"""
Bepaalt welke repository-implementatie gebruikt wordt: rechtstreekse
database-toegang ('db', standaard) of de Joomla Web Services API ('api').

Omschakelen = alleen DATA_BACKEND (en de bijbehorende credentials) in .env
aanpassen. main.py en de MCP-tools veranderen niet mee.
"""

import os


def get_data_backend() -> str:
    return os.environ.get("DATA_BACKEND", "db").lower()


def get_repositories():
    backend = get_data_backend()

    if backend == "db":
        from .repositories.db_repository import DbContentRepository, DbUserRepository

        kwargs = dict(
            host=os.environ.get("DB_HOST", "mariadb"),
            port=int(os.environ.get("DB_PORT", "3306")),
            database=os.environ.get("DB_NAME", "joomla"),
            user=os.environ.get("DB_USER", "mcp_reader"),
            password=os.environ.get("DB_PASSWORD", ""),
            table_prefix=os.environ.get("DB_TABLE_PREFIX", "jos_"),
        )
        return DbContentRepository(**kwargs), DbUserRepository(**kwargs)

    if backend == "api":
        from .repositories.api_repository import ApiContentRepository, ApiUserRepository

        kwargs = dict(
            base_url=os.environ.get("JOOMLA_API_BASE_URL", ""),
            token=os.environ.get("JOOMLA_API_TOKEN", ""),
        )
        return ApiContentRepository(**kwargs), ApiUserRepository(**kwargs)

    raise ValueError(f"Onbekende DATA_BACKEND: '{backend}' (verwacht 'db' of 'api')")
