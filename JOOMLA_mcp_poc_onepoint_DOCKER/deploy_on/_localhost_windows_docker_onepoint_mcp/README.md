# onepoint – laptop (Windows + Docker)

## LET OP:
De snelheid van de website en OpenCode is behoorlijk traag. Dit komt door de combinatie van Windows en WSL die "onder water" gebruikt wordt.
Een variant rechtstreeks op WSL (vergelijkbaar met de Raspberry Pi) zou veel sneller moeten zijn.  

Map: `deploy_on/_legion-2020_docker_onepoint_mcp/`

```
env/                    .env.example  -> kopieer naar .env
website-onepoint        website-stack  (mariadb + Joomla/Akeeba)   – poort 9380
opencode-onepoint       opencode-stack  – poort 4396
```

Algemene uitleg (`.env`-waarden, Akeeba-instellingen, scripts, reset): zie het README in de zip-root.
POC-specifiek: zie het README in `JOOMLA_mcp_poc_onepoint_DOCKER`.

## Eenmalig voorbereiden

1. `env\.env.example` kopiëren naar `env\.env` en invullen.
   ```bat
   copy env\.env.example env\.env
   ```
2. Je `.jpa`-bestand in `website-onepoint\joomla-akeeba\akeeba\` zetten (daar staat al `kickstart.php`).
3. Controleer dat `website-onepoint\joomla-www\` leeg is (alleen `.gitkeep` mag erin).

## Stap 1 – website-stack starten

Gebruik de `.cmd`-scripts vanuit de map `compose_scripts` (niet de `.sh`-scripts; die verwachten `./env/.env`, de Pi-indeling).

```bat
cd website-onepoint\compose_scripts
rebuild_and_start_all_containers.cmd
```

Dit maakt het netwerk `external-mcp-onepoint-net` aan en start `joomla-mariadb-onepoint` en `joomla-webserver-onepoint`.

Het script verwijdert `joomla-www` op de laptop **niet** betrouwbaar (het zoekt `.\joomla-www` in `compose_scripts`, niet in de stack-map). Maak die map bij een herstart zelf leeg, anders slaat Joomla het uitpakken over.

## Stap 2 – site restoren

`http://localhost:9380/kickstart.php` → instellingen volgens de root-README (§3).
Daarna: front-end `http://localhost:9380/`, back-end `http://localhost:9380/administrator/`.

## Stap 3 – opencode-stack starten

```bat
cd ..\..\opencode-onepoint\compose_scripts
rebuild_and_start_all_containers.cmd
```
(of `start_all_containers.cmd` als het netwerk en de images er al zijn)
OpenCode: `http://localhost:4396/`

## Dagelijks gebruik

In beide `compose_scripts`-mappen: `start_all_containers.cmd` / `stop_all_containers.cmd`.
Stop de opencode-stack vóór de website-stack; start eerst de website-stack.

