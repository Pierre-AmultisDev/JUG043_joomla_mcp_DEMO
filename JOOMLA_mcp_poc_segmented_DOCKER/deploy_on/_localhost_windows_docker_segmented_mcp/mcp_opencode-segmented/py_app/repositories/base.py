"""
Het contract dat elke databron moet nakomen. De MCP-tools in main.py roepen
uitsluitend deze methodes aan — nooit rechtstreeks SQL of HTTP. Dat is wat
de databron later (DB -> Joomla Web Services API) vervangbaar maakt zonder
dat de tools of de mensen die ze gebruiken iets merken.
"""

from abc import ABC, abstractmethod
from typing import Optional

from .. import models


class ContentRepository(ABC):
    @abstractmethod
    def search_articles(
        self, query: str, category: Optional[str] = None, limit: int = 10
    ) -> list[models.ArticleSummary]:
        """Zoek artikelen op titel + inhoud (introtext/fulltext)."""

    @abstractmethod
    def get_article(self, article_id: int) -> models.ArticleDetail:
        """Volledige inhoud van één artikel."""

    @abstractmethod
    def get_article_meta(self, article_id: int) -> models.ArticleMeta:
        """Status, hits, aanmaakdatum, auteur, publicatievensters."""


class UserRepository(ABC):
    @abstractmethod
    def list_users(
        self, name_filter: Optional[str] = None, limit: int = 50
    ) -> list[models.UserSummary]:
        """Overzicht van gebruikers, optioneel gefilterd op naam."""

    @abstractmethod
    def get_user(self, user_id: int) -> models.UserDetail:
        """Profiel van één gebruiker, incl. laatste login en groepen."""

    @abstractmethod
    def list_groups(self) -> list[models.Group]:
        """Alle beschikbare gebruikersgroepen."""
