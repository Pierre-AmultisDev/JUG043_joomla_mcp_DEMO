# mcp-server-container

De MCP-server zelf: een Python-proces dat op poort 8000 (intern, 9000 extern)
via `streamable-http` MCP-tools aanbiedt tegen de Joomla-kopie.

## Bestanden

- `Dockerfile` — bouwt de image met `uv` (zie hieronder voor de
  build-context-bijzonderheid).
- `docker-entrypoint.sh` — start `app.main` als langlopend proces
  (`exec python -m app.main`), zodat `docker stop`/`docker compose down`
  het proces netjes kan afsluiten.
- `mgmt_scripts/` — gereserveerd voor eventuele toekomstige
  beheerscripts specifiek voor deze container. Nu nog leeg (`.gitkeep`).

De eigenlijke Python-broncode (`main.py`, `config.py`, `models.py`,
`repositories/`) staat **niet** in deze map, maar in `../../code/py_app/`
(portable, deelbaar met andere deploy-doelen). `copy_files_to_RPI5.sh` zet
die code op de Pi in een losse `py_app/`-map naast deze `mcp-server/`-map.

## Belangrijk: de build-context is niet deze map

In `docker-compose.yml` staat voor deze service:
```yaml
build:
  context: .
  dockerfile: ./mcp-server/Dockerfile
```
De context is dus `deploy_on/_rpi5_docker/` (één niveau hoger), niet
`mcp-server/` zelf. Dat is nodig omdat de `Dockerfile` ook bestanden uit de
naastgelegen `py_app/` en `py_conf/`-mappen moet kunnen kopiëren. Praktisch
gevolg: `.dockerignore` in déze map wordt door Docker genegeerd — de
werkende `.dockerignore` staat op contextniveau (`../.dockerignore`). Zie de
toelichting in `.dockerignore` hier voor details.

## Beschikbare tools

`ping` (health-check) plus 6 read-only tools tegen de Joomla-kopie:
`search_articles`, `get_article`, `get_article_meta`, `list_users`,
`get_user`, `list_groups`. Zie `../../code/README.md` voor details en
`../../code/py_app/repositories/db_repository.py` voor de SQL erachter.

Testen zonder een MCP-client erbij te pakken:
```bash
npx @modelcontextprotocol/inspector
```
en verbind met `http://<pi-ip>:9000/mcp` (extern poortnummer; intern draait
de server op 8000).

## Data-backend omschakelen (DB vs. Joomla API)

Zie `../../code/README.md` en `code/py_app/repositories/base.py` — dit
regel je via `DATA_BACKEND` in `.env`, niet in deze map.
