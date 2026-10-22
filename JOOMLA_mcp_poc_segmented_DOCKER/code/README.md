# Joomla MCP POC

Demo-opstelling voor de JUG043-usergroup: een kopie van een Joomla-site, een
MCP-server die er read-only vragen over kan beantwoorden (artikelen,
gebruikers, groepen), en een externe client (Claude Code / Hermes Agent) die
via MCP met die server praat.

## Structuur

Dit project is opgesplitst in **portable code** (`code/`) en
**deploy-doel-specifieke configuratie** (`deploy_on/<doel>/`), zodat
dezelfde applicatiecode op meerdere plekken uitgerold kan worden.

```
JOOMLA_mcp_poc_DOCKER/
├── code/
│   ├── py_app/                     ← de MCP-server zelf (Python package)
│   │   ├── main.py                 ← 6 MCP-tools + ping (health-check)
│   │   ├── config.py                ← kiest DB- of API-repository
│   │   ├── models.py
│   │   └── repositories/
│   │       ├── base.py             ← contract (interface)
│   │       ├── db_repository.py    ← implementatie: rechtstreeks SQL
│   │       └── api_repository.py   ← implementatie: Joomla Web Services API
│   └── py_conf/_rpi5_docker/
│       ├── pyproject.toml          ← dependencies (geïnstalleerd met uv)
│       ├── uv.lock                 ← reproduceerbare, gepinde versies
│       └── env/.env.example        ← kopieer naar .env in dezelfde map
└── deploy_on/_rpi5_docker/
    ├── docker-compose.yml                 ← met Akeeba-restore
    ├── docker-compose zonder Akeeba.yml    ← zonder Akeeba-restore
    ├── copy_files_to_RPI5.sh
    ├── compose_scripts/                    ← start/stop/rebuild/update
    ├── mariadb/
    │   ├── init/
    │   │   ├── 01-create-readonly-user.sql   ← maakt 'mcp_reader' DB-gebruiker
    │   │   └── 02-joomla-dump.sql            ← vervang door je eigen site-dump
    │   ├── mgmt_scripts/anonymize_members.sh   ← anonimiseert ledengegevens
    │   ├── .dockerignore
    │   └── README.md
    ├── joomla-akeeba/
    │   ├── akeeba/                          ← kickstart.php + .jpa-backup hierin
    │   ├── mgmt_scripts/
    │   ├── .dockerignore
    │   └── README.md
    ├── mcp-server/
    │   ├── Dockerfile
    │   ├── docker-entrypoint.sh
    │   ├── mgmt_scripts/
    │   ├── .dockerignore                    ← let op: build-context is "..", zie README
    │   └── README.md
    ├── opencode/
    │   ├── opencode.json                    ← remote MCP-config + default model (Groq, gratis)
    │   ├── workspace/
    │   └── README.md
    ├── joomla-www/                          ← kopieer/restore hier je Joomla-kopie in
    ├── .dockerignore                         ← de effectieve, voor de mcp-server-build
    └── README.md                             ← volledige Pi 5-installatie- en opstartinstructies
```

Zie **`deploy_on/_rpi5_docker/README.md`** voor de stap-voor-stap installatie
(Docker op de Pi 5) en het opstarten van de stack.

De 6 MCP-tools zijn nu geïmplementeerd tegen de rechtstreekse database-
verbinding (zie hieronder): `search_articles`, `get_article`,
`get_article_meta`, `list_users`, `get_user`, `list_groups`. De queries
gebruiken de klassieke Joomla-kernkolommen (`#__content`, `#__users`,
`#__usergroups`, `#__user_usergroup_map`) en zijn end-to-end getest tegen
een testdatabase met dat schema. Kom je op je eigen sitekopie toch een
"Unknown column"-fout tegen, controleer dan met bv.
`DESCRIBE <prefix>_content;` welke kolommen jouw Joomla-versie gebruikt.

**Let op de tabelprefix:** zet `DB_TABLE_PREFIX` in `.env` op de prefix van
jouw sitekopie (te vinden in `configuration.php` als `$dbprefix`) — een
moderne Joomla-installatie gebruikt meestal geen `jos_` maar een
willekeurige prefix.

---

## Let op: privacygevoelige data (AVG)

Deze kopie bevat echte gebruikersgegevens van de usergroup-site (namen,
e-mailadressen, laatste inlogdatum, groepslidmaatschap), en `list_users`/
`get_user` geven die daadwerkelijk terug, ook aan een cloudmodel. Draai
daarom vóór de demo het anonimiseringsscript:
`deploy_on/_rpi5_docker/mariadb/mgmt_scripts/anonymize_members.sh`
(zie `mariadb/README.md`). Controleer daarna met `--report`.

## Van database naar Joomla API (voor een live situatie)

De MCP-tools praten nooit rechtstreeks met de database of de API — ze
gebruiken een vaste interface (`code/py_app/repositories/base.py`) met
twee implementaties: `db_repository.py` (nu geïmplementeerd, rechtstreeks
SQL) en `api_repository.py` (nog TODO, Joomla Web Services). Overschakelen
op een live site zonder directe DB-toegang is dan:

1. `DATA_BACKEND=api` zetten in `.env`.
2. `JOOMLA_API_BASE_URL` (de kale site-URL, geen `/api/...` erachter) en
   `JOOMLA_API_TOKEN` invullen.
3. In Joomla-backend: bij de gebruiker die de token gebruikt, onder
   "Joomla API-token" een Personal API Token aanmaken (alleen Super Users
   kunnen dit standaard gebruiken).

Geen wijzigingen nodig in `main.py` of in hoe de MCP-tools worden
aangeroepen — dat blijft voor Claude Code / Hermes Agent precies hetzelfde.

`api_repository.py` is geïmplementeerd en inmiddels ook bevestigd tegen
een echte Joomla-site (niet alleen mijn sandbox-simulatie): het
`/v1/users/{id}`-endpoint (let op: `/users/{id}`, niet `/users/users/{id}`)
en de vorm van het `groups`-veld (`{"2": 2, "8": 8}`, id's als sleutel én
waarde) zijn live geverifieerd en verwerkt in `_normalize_groups`.
`get_article`/`get_article_meta`/`search_articles` zijn nog niet live
getest, alleen tegen een gesimuleerde server op basis van de Joomla
5.0.3-broncode (`api/components/com_content`) en de routeregistratie in
`plugins/webservices/*` -- test die dus nog even tegen je eigen Pi.

## Volgende stap

Bouwen/testen op de Pi (`copy_files_to_RPI5.sh` +
`rebuild_and_start_all_containers.sh`), en daarna koppelen met Claude Code
(remote MCP via HTTP, poort 9000) vanaf je laptop. Als daarna nog tijd over
is: de write-tools (artikel aanmaken/wijzigen, media uploaden) en/of de
vergelijking met Hermes Agent.
