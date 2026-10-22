# POC senso

**Idee:** OpenCode praat via de **standaard Joomla Web Services API** met Joomla:
`http://joomla-webserver-senso:80/api/index.php/v1/mcp`, met een Bearer API-token in
`opencode/opencode.json`. Geen aparte MCP-server, geen DB-gebruiker voor de AI.

- Containers: `joomla-mariadb-senso`, `joomla-webserver-senso` (website-stack) en `opencode-ui-senso` (opencode-stack).
- Poorten: web **9280**, OpenCode **4296**.
- Netwerk: `external-mcp-senso-net`.

**Vereisten voor werking**
- De gerestorede site moet de API/MCP-route aanbieden en het token in `opencode.json` moet in die site geldig zijn (API-gebruiker + token).
- Eerst de website-stack starten en restoren, dán de opencode-stack.
