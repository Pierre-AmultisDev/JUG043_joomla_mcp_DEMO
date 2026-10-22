#!/bin/bash
# =============================================================================
#
# @package    JUG043_joomla_mcp_DEMO
# @container  Joomla MCP PoC
# @name       start_all_containers.sh
# @purpose    Shell script to start building all containers/services defined in dockercompose.yml
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

  # https://docs.docker.com/reference/cli/docker/compose/up/
  # --build     rebuild if need be
  # --progres   plain No escape codes / no colors
  # --detach    start containers in background
  docker compose --env-file "$ENV_FILE" up --build --detach 2>&1 | tee "$LOGFILE"

else
  echo "Docker compose config file validation failed. Did nothing further"
fi
