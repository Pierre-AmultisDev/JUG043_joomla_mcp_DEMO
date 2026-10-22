# segmented – laptop (Windows + Docker)

Map: `deploy_on/_legion-2020_docker_segmented_mcp/`

```
env/                    .env.example  -> kopieer naar .env
website-segmented       website-stack  (mariadb + Joomla/Akeeba)   – poort 9180
mcp_opencode-segmented  opencode-stack (MCP-server + OpenCode)  – poort 4196
```

Algemene uitleg (`.env`-waarden, Akeeba-instellingen, scripts, reset): zie het README in de zip-root.
POC-specifiek: zie het README in `JOOMLA_mcp_poc_segmented_DOCKER`.

## Eenmalig voorbereiden

1. `env\.env.example` kopiëren naar `env\.env` en invullen.
   ```bat
   copy env\.env.example env\.env
   ```
2. Je `.jpa`-bestand in `website-segmented\joomla-akeeba\akeeba\` zetten (daar staat al `kickstart.php`).
3. Controleer dat `website-segmented\joomla-www\` leeg is (alleen `.gitkeep` mag erin).

## Stap 1 – website-stack starten

Gebruik de `.cmd`-scripts vanuit de map `compose_scripts` (niet de `.sh`-scripts; die verwachten `./env/.env`, de Pi-indeling).

```bat
cd website-segmented\compose_scripts
rebuild_and_start_all_containers.cmd
```

Dit maakt het netwerk `external-mcp-segmented-net` aan en start `joomla-mariadb-segmented` en `joomla-webserver-segmented`.

Het script verwijdert `joomla-www` op de laptop **niet** betrouwbaar (het zoekt `.\joomla-www` in `compose_scripts`, niet in de stack-map). Maak die map bij een herstart zelf leeg, anders slaat Joomla het uitpakken over.

## Stap 2 – site restoren

`http://localhost:9180/kickstart.php` → instellingen volgens de root-README (§3).
Daarna: front-end `http://localhost:9180/`, back-end `http://localhost:9180/administrator/`.

## Stap 3 – opencode-stack starten

```bat
cd ..\..\mcp_opencode-segmented\compose_scripts
rebuild_and_start_all_containers.cmd
```
(of `start_all_containers.cmd` als het netwerk en de images er al zijn)
Controleer na het starten of de MCP-server draait: `docker logs joomla-mcp-server-segmented` (opstartbanner) en `http://localhost:9100/mcp`.

OpenCode: `http://localhost:4196/`

## Dagelijks gebruik

In beide `compose_scripts`-mappen: `start_all_containers.cmd` / `stop_all_containers.cmd`.
Stop de opencode-stack vóór de website-stack; start eerst de website-stack.
`update_all_apps_in_containers.cmd` ververst de images (let op de `image prune -af`, zie root-README §4).
