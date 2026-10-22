"""
Gedeelde datastructuren. Elke repository-implementatie (DB of API) geeft
dezelfde objecten terug, zodat main.py nooit hoeft te weten welke bron
erachter zit.
"""

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class ArticleSummary:
    id: int
    title: str
    snippet: str


@dataclass
class ArticleDetail:
    id: int
    title: str
    introtext: str
    fulltext: str
    category: str


@dataclass
class ArticleMeta:
    id: int
    state: str          # published / unpublished / archived / trashed
    hits: int
    created: str
    author: str
    publish_up: Optional[str] = None
    publish_down: Optional[str] = None


@dataclass
class UserSummary:
    id: int
    name: str
    username: str
    active: bool


@dataclass
class UserDetail:
    id: int
    name: str
    username: str
    email: str
    active: bool
    last_login: Optional[str] = None
    groups: list[str] = field(default_factory=list)


@dataclass
class Group:
    id: int
    title: str
    parent_id: Optional[int] = None
