# senso – Raspberry Pi 5

Map: `deploy_on/_rpi5_docker_senso_mcp/`

```
env/           .env.example  -> kopieer naar .env (op de Windows/WSL-kant)
website       website-stack  -> Pi: ~/docker/JOOMLA_mcp_poc_senso_web_DOCKER   – poort 9280
opencode      OpenCode-stack  -> Pi: ~/docker/JOOMLA_mcp_poc_senso_mcp_DOCKER   – poort 4296
```

Algemene uitleg (`.env`-waarden, Akeeba-instellingen, scripts, reset): zie het README in de zip-root.
POC-specifiek: zie het README in `JOOMLA_mcp_poc_senso_DOCKER`.

De Pi krijgt een **platte** map per stack: `docker-compose.yml`, de scripts uit `compose_scripts/`, `env/.env` en de submappen staan naast elkaar.
Scripts draai je dus rechtstreeks in die map, bijvoorbeeld `./start_all_containers.sh`.

## Eenmalig voorbereiden (op de Windows-machine)

1. `env/.env.example` kopiëren naar `env/.env` en invullen.
2. Je `.jpa` in `website/joomla-akeeba/akeeba/` zetten (naast `kickstart.php`).
3. In `website/copy_files_to_RPI5.sh` en `opencode/copy_files_to_RPI5.sh` staan een vast Pi-adres
   (`ubuntu@RPi5-UB2404-001-WIRE`) en een vast Windows-pad (`/mnt/c/@my_projects/_rpi5_joomla_mcp/...`) – pas dat aan als jouw situatie anders is.
   Er moet SSH-toegang tot de Pi zijn en `rsync` in WSL.

## Stap 1 – website-stack kopiëren en starten

Op Windows, in een WSL-terminal:
```bash
cd website
./copy_files_to_RPI5.sh
```
Op de Pi:
```bash
ssh ubuntu@rpi5-ub2404-001-wire
cd ~/docker/JOOMLA_mcp_poc_senso_web_DOCKER
chmod +x *.sh
./rebuild_and_start_all_containers.sh
```
Het script vraagt om `sudo` (het wist `./joomla-www`) en maakt het netwerk aan. Bij het einde worden de Akeeba-instellingen herhaald.

## Stap 2 – site restoren

`http://rpi5-ub2404-001-wire:9280/kickstart.php` → instellingen volgens de root-README (§3).
Front-end `http://rpi5-ub2404-001-wire:9280/`, back-end `…/administrator/`.

## Stap 3 – opencode-stack kopiëren en starten

```bash
# Windows/WSL
cd ../opencode
./copy_files_to_RPI5.sh
```
```bash
# Pi
cd ~/docker/JOOMLA_mcp_poc_senso_mcp_DOCKER
chmod +x *.sh
./rebuild_and_start_all_containers.sh
```
OpenCode: `http://rpi5-ub2404-001-wire:4296/`
## Dagelijks gebruik

In beide mappen op de Pi: `./start_all_containers.sh` en `./stop_all_containers.sh`. Eerst de website-stack starten, als laatste stoppen.
`./update_all_apps_in_containers.sh` ververst de images (let op de `image prune -af`, zie root-README §4).

**Niet opnieuw `rebuild_…` draaien na een geslaagde restore** tenzij je de site opnieuw wilt restoren: het wist `joomla-www`, terwijl de database in het volume blijft staan.
