"""
Implementatie #1: rechtstreeks read-only tegen de MariaDB-container
('mcp_reader'-gebruiker, alleen SELECT-rechten).

Kolomnamen zijn de "klassieke" Joomla-kernkolommen (#__content, #__users,
#__usergroups, #__user_usergroup_map) die al sinds Joomla 1.5 stabiel zijn.
Kom je hier toch een "Unknown column"-fout tegen op jouw kopie, check dan
met bv. `DESCRIBE <prefix>_content;` op de container welke kolommen jouw
Joomla-versie daadwerkelijk gebruikt.
"""

import re

import pymysql

from .. import models
from .base import ContentRepository, UserRepository


def _strip_html(text: str | None, max_length: int | None = None) -> str:
    """Simpele opschoning van Joomla-HTML voor leesbare tool-output."""
    if not text:
        return ""
    plain = re.sub(r"<[^>]+>", " ", text)
    plain = re.sub(r"\s+", " ", plain).strip()
    if max_length is not None and len(plain) > max_length:
        plain = plain[:max_length].rstrip() + "…"
    return plain


class DbConnectionMixin:
    def __init__(
        self,
        host: str,
        port: int,
        database: str,
        user: str,
        password: str,
        table_prefix: str = "jos_",
    ):
        self._conn_kwargs = dict(
            host=host,
            port=port,
            database=database,
            user=user,
            password=password,
            cursorclass=pymysql.cursors.DictCursor,
            charset="utf8mb4",
        )
        self.prefix = table_prefix

    def _t(self, name: str) -> str:
        """Backtick-quoted, geprefixte tabelnaam, bv. _t('content') -> `jos_content`."""
        return f"`{self.prefix}{name}`"

    def _query(self, sql: str, params: dict | None = None, fetchone: bool = False):
        conn = pymysql.connect(**self._conn_kwargs)
        try:
            with conn.cursor() as cur:
                cur.execute(sql, params or {})
                return cur.fetchone() if fetchone else cur.fetchall()
        finally:
            conn.close()


# Joomla's state-kolom: 1=gepubliceerd, 0=ongepubliceerd, 2=gearchiveerd, -2=prullenbak
_ARTICLE_STATE_LABELS = {1: "published", 0: "unpublished", 2: "archived", -2: "trashed"}


class DbContentRepository(DbConnectionMixin, ContentRepository):
    def search_articles(self, query, category=None, limit=10):
        sql = f"""
            SELECT c.id, c.title, c.introtext, c.`fulltext`
            FROM {self._t('content')} c
        """
        params: dict = {"q": f"%{query}%", "limit": limit}

        where = ["(c.title LIKE %(q)s OR c.introtext LIKE %(q)s OR c.`fulltext` LIKE %(q)s)"]
        if category:
            sql += f" JOIN {self._t('categories')} cat ON cat.id = c.catid"
            where.append("cat.title = %(category)s")
            params["category"] = category

        sql += " WHERE " + " AND ".join(where)
        sql += " ORDER BY c.created DESC LIMIT %(limit)s"

        rows = self._query(sql, params)
        results = []
        for r in rows:
            combined = f"{r['introtext'] or ''} {r['fulltext'] or ''}"
            results.append(
                models.ArticleSummary(
                    id=r["id"],
                    title=r["title"],
                    snippet=_strip_html(combined, max_length=200),
                )
            )
        return results

    def get_article(self, article_id):
        sql = f"""
            SELECT c.id, c.title, c.introtext, c.`fulltext`, cat.title AS category
            FROM {self._t('content')} c
            LEFT JOIN {self._t('categories')} cat ON cat.id = c.catid
            WHERE c.id = %(id)s
        """
        row = self._query(sql, {"id": article_id}, fetchone=True)
        if row is None:
            raise ValueError(f"Artikel met id {article_id} niet gevonden.")
        return models.ArticleDetail(
            id=row["id"],
            title=row["title"],
            introtext=_strip_html(row["introtext"]),
            fulltext=_strip_html(row["fulltext"]),
            category=row["category"] or "(onbekende categorie)",
        )

    def get_article_meta(self, article_id):
        sql = f"""
            SELECT c.state, c.hits, c.created, c.publish_up, c.publish_down, u.name AS author
            FROM {self._t('content')} c
            LEFT JOIN {self._t('users')} u ON u.id = c.created_by
            WHERE c.id = %(id)s
        """
        row = self._query(sql, {"id": article_id}, fetchone=True)
        if row is None:
            raise ValueError(f"Artikel met id {article_id} niet gevonden.")
        return models.ArticleMeta(
            id=article_id,
            state=_ARTICLE_STATE_LABELS.get(row["state"], str(row["state"])),
            hits=row["hits"],
            created=str(row["created"]) if row["created"] else "",
            author=row["author"] or "(onbekende auteur)",
            publish_up=str(row["publish_up"]) if row["publish_up"] else None,
            publish_down=str(row["publish_down"]) if row["publish_down"] else None,
        )


class DbUserRepository(DbConnectionMixin, UserRepository):
    def list_users(self, name_filter=None, limit=50):
        sql = f"SELECT id, name, username, block FROM {self._t('users')}"
        params: dict = {"limit": limit}
        if name_filter:
            sql += " WHERE name LIKE %(nf)s OR username LIKE %(nf)s"
            params["nf"] = f"%{name_filter}%"
        sql += " ORDER BY name LIMIT %(limit)s"

        rows = self._query(sql, params)
        return [
            models.UserSummary(
                id=r["id"], name=r["name"], username=r["username"], active=(r["block"] == 0)
            )
            for r in rows
        ]

    def get_user(self, user_id):
        sql = f"""
            SELECT id, name, username, email, block, lastvisitDate
            FROM {self._t('users')}
            WHERE id = %(id)s
        """
        row = self._query(sql, {"id": user_id}, fetchone=True)
        if row is None:
            raise ValueError(f"Gebruiker met id {user_id} niet gevonden.")

        groups_sql = f"""
            SELECT g.title
            FROM {self._t('usergroups')} g
            JOIN {self._t('user_usergroup_map')} m ON m.group_id = g.id
            WHERE m.user_id = %(id)s
            ORDER BY g.title
        """
        group_rows = self._query(groups_sql, {"id": user_id})

        return models.UserDetail(
            id=row["id"],
            name=row["name"],
            username=row["username"],
            email=row["email"],
            active=(row["block"] == 0),
            last_login=str(row["lastvisitDate"]) if row["lastvisitDate"] else None,
            groups=[g["title"] for g in group_rows],
        )

    def list_groups(self):
        sql = f"SELECT id, title, parent_id FROM {self._t('usergroups')} ORDER BY lft"
        rows = self._query(sql)
        return [
            models.Group(id=r["id"], title=r["title"], parent_id=r["parent_id"]) for r in rows
        ]
