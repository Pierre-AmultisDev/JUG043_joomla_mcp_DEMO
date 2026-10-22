"""
Implementatie #2: Joomla Web Services (REST/JSON:API) i.p.v. rechtstreekse
databasetoegang. Bedoeld voor een live site waar directe DB-toegang niet
mogelijk/wenselijk is.

De endpoints, queryparameters en veldnamen hieronder zijn geverifieerd tegen
de ECHTE broncode van Joomla 5.0.3 (api/components/com_content en
api/components/com_users), niet uit het geheugen gereconstrueerd. Wat NIET
geverifieerd is: een live HTTP-round-trip (zie de toelichting bij
_normalize_groups hieronder voor het enige punt met resterende onzekerheid).
Test dit dus alsnog tegen je eigen Pi voordat je het in de demo gebruikt.

Authenticatie: een "Personal API Token" van een gebruiker (aan te maken in
de Joomla-backend onder Gebruikers > je account bewerken > tabblad "Joomla
API Token"), meegegeven als 'Authorization: Bearer <token>'-header. Zonder
extra plugin-configuratie mogen alleen Super Users een token gebruiken.
"""

import re
from typing import Optional

import httpx

from .. import models
from .base import ContentRepository, UserRepository


def _strip_html(text: Optional[str], max_length: Optional[int] = None) -> str:
    """Simpele opschoning van Joomla-HTML voor leesbare tool-output.
    Zelfde implementatie als in db_repository.py, bewust hier gedupliceerd
    zodat elke repository-implementatie op zichzelf staat."""
    if not text:
        return ""
    plain = re.sub(r"<[^>]+>", " ", text)
    plain = re.sub(r"\s+", " ", plain).strip()
    if max_length is not None and len(plain) > max_length:
        plain = plain[:max_length].rstrip() + "…"
    return plain


_ARTICLE_STATE_LABELS = {1: "published", 0: "unpublished", 2: "archived", -2: "trashed"}


class ApiConnectionMixin:
    def __init__(self, base_url: str, token: str, timeout: float = 15.0):
        if not base_url:
            raise ValueError("JOOMLA_API_BASE_URL is niet gezet.")
        if not token:
            raise ValueError("JOOMLA_API_TOKEN is niet gezet.")
        # Joomla's Web Services API zit altijd onder /api/index.php/v1,
        # ongeacht wat er in JOOMLA_API_BASE_URL staat (dat is de kale
        # site-URL, bv. https://jug043.example.org).
        self.api_root = base_url.rstrip("/") + "/api/index.php/v1"
        self._client = httpx.Client(
            base_url=self.api_root,
            headers={
                "Authorization": f"Bearer {token}",
                "Accept": "application/vnd.api+json",
            },
            timeout=timeout,
        )

    def _get(self, path: str, params: Optional[dict] = None) -> Optional[dict]:
        resp = self._client.get(path, params=params or {})
        if resp.status_code == 404:
            return None
        resp.raise_for_status()
        return resp.json()

    def _get_category_title(self, catid) -> Optional[str]:
        if catid is None:
            return None
        # com_content heeft geen eigen CategoriesController met filters, dus
        # we halen de (kleine) lijst op en matchen zelf op id.
        data = self._get("/content/categories", params={"page[limit]": 200})
        for item in (data or {}).get("data", []):
            if str(item.get("id")) == str(catid):
                return item.get("attributes", {}).get("title")
        return None

    def _resolve_category_id(self, name: str) -> Optional[int]:
        data = self._get("/content/categories", params={"page[limit]": 200})
        needle = name.strip().lower()
        for item in (data or {}).get("data", []):
            title = (item.get("attributes", {}).get("title") or "").strip().lower()
            if title == needle:
                return int(item["id"])
        return None

    def _get_user_name(self, user_id) -> Optional[str]:
        if user_id is None:
            return None
        data = self._get(f"/users/{user_id}")
        if not data or "data" not in data:
            return None
        return data["data"].get("attributes", {}).get("name")


class ApiContentRepository(ApiConnectionMixin, ContentRepository):
    def search_articles(self, query, category=None, limit=10):
        params = {"filter[search]": query, "page[limit]": limit}
        if category:
            cat_id = self._resolve_category_id(category)
            if cat_id is not None:
                params["filter[category]"] = cat_id
            # Onbekende categorienaam: filter negeren i.p.v. hard falen,
            # zodat een tikfout niet meteen 0 resultaten oplevert.

        data = self._get("/content/articles", params=params)
        results = []
        for item in (data or {}).get("data", []):
            attrs = item.get("attributes", {})
            combined = f"{attrs.get('introtext') or ''} {attrs.get('fulltext') or ''}"
            results.append(
                models.ArticleSummary(
                    id=int(item["id"]),
                    title=attrs.get("title", ""),
                    snippet=_strip_html(combined, max_length=200),
                )
            )
        return results

    def get_article(self, article_id):
        data = self._get(f"/content/articles/{article_id}")
        if not data or "data" not in data:
            raise ValueError(f"Artikel met id {article_id} niet gevonden.")
        item = data["data"]
        attrs = item.get("attributes", {})
        return models.ArticleDetail(
            id=int(item["id"]),
            title=attrs.get("title", ""),
            introtext=_strip_html(attrs.get("introtext")),
            fulltext=_strip_html(attrs.get("fulltext")),
            category=self._get_category_title(attrs.get("catid")) or "(onbekende categorie)",
        )

    def get_article_meta(self, article_id):
        data = self._get(f"/content/articles/{article_id}")
        if not data or "data" not in data:
            raise ValueError(f"Artikel met id {article_id} niet gevonden.")
        attrs = data["data"].get("attributes", {})
        return models.ArticleMeta(
            id=article_id,
            state=_ARTICLE_STATE_LABELS.get(attrs.get("state"), str(attrs.get("state"))),
            hits=attrs.get("hits", 0),
            created=attrs.get("created") or "",
            author=self._get_user_name(attrs.get("created_by")) or "(onbekende auteur)",
            publish_up=attrs.get("publish_up") or None,
            publish_down=attrs.get("publish_down") or None,
        )


class ApiUserRepository(ApiConnectionMixin, UserRepository):
    def list_users(self, name_filter=None, limit=50):
        params = {"page[limit]": limit}
        if name_filter:
            params["filter[search]"] = name_filter

        data = self._get("/users", params=params)
        results = []
        for item in (data or {}).get("data", []):
            attrs = item.get("attributes", {})
            results.append(
                models.UserSummary(
                    id=int(item["id"]),
                    name=attrs.get("name", ""),
                    username=attrs.get("username", ""),
                    active=(attrs.get("block") == 0),
                )
            )
        return results

    def get_user(self, user_id):
        data = self._get(f"/users/{user_id}")
        if not data or "data" not in data:
            raise ValueError(f"Gebruiker met id {user_id} niet gevonden.")
        item = data["data"]
        attrs = item.get("attributes", {})
        return models.UserDetail(
            id=int(item["id"]),
            name=attrs.get("name", ""),
            username=attrs.get("username", ""),
            email=attrs.get("email", ""),
            active=(attrs.get("block") == 0),
            last_login=attrs.get("lastvisitDate") or None,
            groups=self._normalize_groups(attrs.get("groups")),
        )

    def _normalize_groups(self, raw) -> list[str]:
        """Vertaalt het 'groups'-attribuut van een los gebruikersitem naar
        een lijst groepsnamen.

        Live getest tegen een echte Joomla-site (Joomla 5): de vorm is een
        object met group-id als sleutel EN waarde, bv.
        {"2": 2, "8": 8, "10": 10} -- geen array, geen titels erbij. Die
        titels zoeken we op via list_groups(). De overige takken hieronder
        zijn defensieve fallbacks voor het geval een andere Joomla-versie
        dit anders rendert; niet live bevestigd."""
        if not raw:
            return []
        if isinstance(raw, dict):
            id_to_title = {str(grp.id): grp.title for grp in self.list_groups()}
            return [id_to_title.get(str(v), str(v)) for v in raw.values()]
        if isinstance(raw, str):
            return [g.strip() for g in raw.split("\n") if g.strip()]
        if isinstance(raw, list):
            titles: list[str] = []
            id_to_title = None
            for g in raw:
                if isinstance(g, dict) and "title" in g:
                    titles.append(g["title"])
                elif isinstance(g, (int, str)):
                    if id_to_title is None:
                        id_to_title = {str(grp.id): grp.title for grp in self.list_groups()}
                    titles.append(id_to_title.get(str(g), str(g)))
            return titles
        return []

    def list_groups(self):
        data = self._get("/users/groups", params={"page[limit]": 200})
        results = []
        for item in (data or {}).get("data", []):
            attrs = item.get("attributes", {})
            results.append(
                models.Group(
                    id=int(item["id"]),
                    title=attrs.get("title", ""),
                    parent_id=attrs.get("parent_id"),
                )
            )
        return results
