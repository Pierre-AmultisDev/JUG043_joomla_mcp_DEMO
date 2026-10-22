#!/bin/bash
# =============================================================================
#
# @package    JUG043_joomla_mcp_DEMO
# @container  Joomla MCP PoC
# @name       update_all_apps_in_containers.sh
# @purpose    Shell script to rebuild ad update all containers/services defined in dockercompose.yml
# @version    v0.0.4  2026-10-22
# @author     pierre@amultis.dev
# @copyright  (C) Pierre Veelen
#
# =============================================================================
LOGFILE="docker_build_$(date +%Y%m%d_%H%M%S).log"
# https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/#use-the-env_file-attribute
# Using an .env file lets you use the same file for use by a plain docker run --env-file ... command, 
# or to share the same .env file within multiple services without the need to duplicate a long environment YAML block.
ENV_FILE="./env/.env"

# https://docs.docker.com/reference/cli/docker/compose/config/
# --quiet       only validate the configuration, don't print anything
if docker compose --env-file "$ENV_FILE" config --quiet; then

  # https://docs.docker.com/reference/cli/docker/compose/pull/
  # Haal de laatste versie op van alle services die een "image:" gebruiken
  # (dus geen eigen Dockerfile/build-sectie hebben, zoals bv. Uptime Kuma)
  echo "Ophalen van laatste images voor services zonder build-sectie..."
  docker compose --env-file "$ENV_FILE" pull

  #https://docs.docker.com/reference/cli/docker/compose/build/
  # --progress  plain No escape codes / no colors
  # --no-cache  negeer alle layer cache, elke stap wordt opnieuw uitgevoerd
  # --pull      haal altijd de laatste base images op i.p.v. lokale kopie
  # (Bouwt alleen services die in dockercompose.yml een "build:" sectie hebben;
  #  services die alleen "image:" gebruiken worden hierboven al bijgewerkt)
  docker compose --env-file "$ENV_FILE" --progress=plain build --no-cache --pull 2>&1 | tee "$LOGFILE"

  # https://docs.docker.com/reference/cli/docker/compose/up/
  # --detach    start containers in background
  docker compose --env-file "$ENV_FILE" up --detach

  # https://docs.docker.com/reference/cli/docker/image_prune/
  # Ruim alle ongebruikte images (ook oude getagde versies) en hun layers op
  # die zijn achtergebleven door de --no-cache build hierboven.
  # 
  # Let op: docker image prune -af verwijderd alles ook van andere stacks!
  # -f          geen bevestiging vragen
  # -a          ook ongebruikte getagde images verwijderen, niet alleen dangling
  echo "Opruimen van oude, ongebruikte images en layers..."
  docker image prune
  docker builder prune

else
  echo "Docker compose config file validation failed. Did nothing further"

fi