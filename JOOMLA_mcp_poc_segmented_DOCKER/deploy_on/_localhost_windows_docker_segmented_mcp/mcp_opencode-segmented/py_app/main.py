"""
MCP-server voor de Joomla JUG043-POC.

Biedt 6 read-only tools aan tegen een kopie van de Joomla-site:
  - search_articles(query, category?, limit?)
  - get_article(article_id)
  - get_article_meta(article_id)
  - list_users(name_filter?, limit?)
  - get_user(user_id)
  - list_groups()

Welke databron erachter zit (rechtstreekse database of de Joomla Web
Services API) wordt bepaald door DATA_BACKEND in .env, zie config.py.
"""

from dataclasses import asdict

from mcp.server.mcpserver import MCPServer

from .config import get_repositories

# content_repo / user_repo zijn ofwel de DB- ofwel de API-implementatie,
# bepaald door DATA_BACKEND in .env (zie config.py). De tools hieronder
# weten dat verschil niet en hoeven dat ook niet te weten.
content_repo, user_repo = get_repositories()

mcp = MCPServer("joomla-mcp")


@mcp.tool()
def ping() -> str:
    """Health-check: bevestigt dat de MCP-server bereikbaar is."""
    return "pong from joomla-mcp-server"


@mcp.tool()
def search_articles(query: str, category: str | None = None, limit: int = 10) -> list[dict]:
    """Zoek artikelen op basis van titel en inhoud (introtext/fulltext).

    'category' is de naam van een categorie (bv. 'Nieuws'), geen id.
    Geeft per treffer id, titel en een kort tekstfragment terug -- gebruik
    daarna get_article(id) of get_article_meta(id) voor meer details.
    """
    results = content_repo.search_articles(query, category=category, limit=limit)
    return [asdict(r) for r in results]


@mcp.tool()
def get_article(article_id: int) -> dict:
    """Volledige inhoud van één artikel (introtext, fulltext, categorie)."""
    return asdict(content_repo.get_article(article_id))


@mcp.tool()
def get_article_meta(article_id: int) -> dict:
    """Metadata van een artikel: publicatiestatus, aantal keer gelezen
    (hits), aanmaakdatum, auteur en publicatievensters."""
    return asdict(content_repo.get_article_meta(article_id))


@mcp.tool()
def list_users(name_filter: str | None = None, limit: int = 50) -> list[dict]:
    """Overzicht van gebruikers, optioneel gefilterd op (deel van) naam of
    gebruikersnaam. Zonder filter: de eerste 'limit' gebruikers."""
    results = user_repo.list_users(name_filter=name_filter, limit=limit)
    return [asdict(r) for r in results]


@mcp.tool()
def get_user(user_id: int) -> dict:
    """Profiel van één gebruiker: naam, e-mail, actief/geblokkeerd,
    laatste inlogdatum en de groepen waar de gebruiker lid van is."""
    return asdict(user_repo.get_user(user_id))


@mcp.tool()
def list_groups() -> list[dict]:
    """Alle beschikbare gebruikersgroepen (id, naam, bovenliggende groep)."""
    return [asdict(g) for g in user_repo.list_groups()]


if __name__ == "__main__":
    # host="0.0.0.0" is verplicht binnen een container: zonder expliciete
    # host/port bindt MCPServer (mcp-SDK v2.x) standaard aan 127.0.0.1, dat
    # is dan alleen bereikbaar BINNEN de container, niet via de poort-mapping
    # (9000:8000) in docker-compose.yml.
    mcp.run(transport="streamable-http", host="0.0.0.0", port=8000)
