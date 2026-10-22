#!/bin/sh
# =============================================================================
# docker-entrypoint.sh
#
# Start de Joomla MCP-server als langlopend proces (blijft luisteren op
# poort 8000, in tegenstelling tot een eenmalig script dat stopt na afloop).
# =============================================================================
set -e

DATA_BACKEND="${DATA_BACKEND:-db}"
DB_HOST="${DB_HOST:-mariadb}"

echo "[docker-entrypoint.sh]============================================================"
echo "[docker-entrypoint.sh]  Joomla MCP-server wordt gestart"
echo "[docker-entrypoint.sh]  Data-backend : ${DATA_BACKEND}"
echo "[docker-entrypoint.sh]  DB host      : ${DB_HOST}"
echo "[docker-entrypoint.sh]============================================================"

# "exec" zorgt dat het python-proces PID 1 wordt en signalen (bv. SIGTERM
# van "docker compose down") correct ontvangt in plaats van te worden
# genegeerd door een tussenliggend shell-proces.
exec python -m app.main
