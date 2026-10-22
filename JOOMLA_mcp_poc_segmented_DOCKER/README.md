# POC segmented

**Idee:** de AI krijgt géén toegang tot Joomla zelf, maar tot een **eigen, gescheiden
Python MCP-server** (`code/py_app`) met 6 read-only tools (`search_articles`, `get_article`,
`get_article_meta`, `list_users`, `get_user`, `list_groups`) plus `ping`. De server leest standaard
rechtstreeks in de database met de read-only gebruiker `mcp_reader`
(`DATA_BACKEND=db`; `api` gebruikt de Joomla Web Services API, met `JOOMLA_API_BASE_URL` + `JOOMLA_API_TOKEN`).

- Containers: `joomla-mariadb-segmented`, `joomla-webserver-segmented` (website-stack);
  `joomla-mcp-server-segmented` en `opencode-ui-segmented` (mcp_opencode-stack).
- Poorten: web **9180**, MCP-server **9100** (intern 8000, pad `/mcp`), OpenCode **4196**.
- OpenCode gebruikt `http://mcp-server-segmented:8000/mcp` (zonder token).
- Code: `code/py_app` (Python), `code/py_conf/_rpi5_docker` (Pi) en `_legion-2020-venv` (lokale venv-templates). Op de laptop zit een kopie van de code in `mcp_opencode-segmented/py_app` en `py_conf`; de Pi-variant krijgt de code via `copy_files_to_RPI5.sh` uit `code/`.

**Let op: wachtwoord van `mcp_reader`**
`mariadb/init/01-create-readonly-user.sql` maakt `mcp_reader` aan met een vast wachtwoord en leest `.env` niet.
`MCP_READER_PASSWORD` in `.env` moet daarom **exact gelijk** zijn aan dat wachtwoord in het SQL-bestand, anders
kan de MCP-server niet inloggen (en anders dan bij de overige `.env`-waarden werkt een latere wijziging alleen na `down -v`,
omdat het init-script alleen bij een leeg volume draait). Wijzig je `MYSQL_DATABASE`, pas dan ook de `GRANT … ON joomla.*` in dat bestand aan.

**Volgorde:** website-stack starten + restoren → daarna de mcp_opencode-stack.
Beide stacks delen het Docker-netwerk `external-mcp-segmented-net`.
