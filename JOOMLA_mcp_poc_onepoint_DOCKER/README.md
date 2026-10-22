# POC onepoint

**Idee:** OpenCode praat rechtstreeks met een MCP-endpoint dat *in Joomla zelf* zit
(component `com_mcpserver`). Er is dus geen aparte MCP-server en geen directe
database-toegang voor de AI.

- Endpoint (zie `opencode/opencode.json`): `http://joomla-webserver-onepoint:80/index.php?option=com_mcpserver&task=rpc.handle`
- Authenticatie: een Bearer API-token in `opencode.json`.
- Containers: `joomla-mariadb-onepoint`, `joomla-webserver-onepoint` (website-stack) en `opencode-ui-onepoint` (opencode-stack).
- Poorten: web **9380**, OpenCode **4396**.

**Vereisten voor werking**
- De gerestorede site moet `com_mcpserver` bevatten en het token in `opencode.json` moet in die site geldig zijn.
- Eerst de website-stack starten en restoren, dán pas de opencode-stack: OpenCode haalt de MCP-tools bij het opstarten op via het Docker-netwerk `external-mcp-onepoint-net`.
