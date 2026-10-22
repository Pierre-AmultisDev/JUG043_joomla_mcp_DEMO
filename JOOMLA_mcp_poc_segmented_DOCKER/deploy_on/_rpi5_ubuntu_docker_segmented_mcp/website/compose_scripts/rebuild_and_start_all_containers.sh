#!/bin/bash
# =============================================================================
#
# @package    JUG043_joomla_mcp_DEMO
# @container  Joomla MCP POC
# @name       start_all_containers.sh
# @purpose    Fully rebuild and start all Docker containers/services
# @version    v0.0.4  2026-10-22
#
# =============================================================================
LOGFILE="docker_build_$(date +%Y%m%d_%H%M%S).log"
# https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/#use-the-env_file-attribute
# Using an .env file lets you use the same file for use by a plain docker run --env-file ... command, 
# or to share the same .env file within multiple services without the need to duplicate a long environment YAML block.
ENV_FILE="./env/.env"

EXTERNAL_NETWORK_NAME="external-mcp-segmented-net"

# =============================================================================
# Check network
# =============================================================================
echo "Controleren of Docker netwerk '$EXTERNAL_NETWORK_NAME' bestaat..."

# Controleer of de netwerknaam exact voorkomt in de lijst van Docker
if docker network ls --format "{{.Name}}" | grep -qx "$EXTERNAL_NETWORK_NAME"; then
    echo "[INFO] Het netwerk '$EXTERNAL_NETWORK_NAME' bestaat al. We gaan verder..."
else
    echo "[OK] Netwerk niet gevonden. Aanmaken van '$EXTERNAL_NETWORK_NAME'..."
    docker network create "$EXTERNAL_NETWORK_NAME"
fi

# Hier gaat je script gewoon verder
echo -e "\n[STATUS] Klaar! Je kunt nu docker-compose up starten."

# =============================================================================
# Check environment file
# =============================================================================

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: Environment file not found: $ENV_FILE"
    exit 1
fi

echo "Using environment file: $ENV_FILE" | tee "$LOGFILE"

# =============================================================================
# Validate Docker Compose configuration
# =============================================================================

if docker compose --env-file "$ENV_FILE" config --quiet; then

    echo "Docker Compose configuration is valid." | tee -a "$LOGFILE"

else

    echo "ERROR: Docker Compose configuration validation failed." | tee -a "$LOGFILE"
    exit 1

fi

# =============================================================================
# Full rebuild
# =============================================================================

echo "Starting FULL Docker rebuild..." | tee -a "$LOGFILE"

# verwijder joomla-www helemaal. Installatie script moet folder aanmaken. 
# anders kan daar niet in geschreven worden.
sudo rm -rf ./joomla-www

docker compose \
    --env-file "$ENV_FILE" \
    --progress=plain \
    build \
    --no-cache \
    --pull \
    2>&1 | tee -a "$LOGFILE"

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    echo "ERROR: Docker image build failed." | tee -a "$LOGFILE"
    exit 1
fi

# =============================================================================
# Recreate containers
# =============================================================================

echo "Recreating containers..." | tee -a "$LOGFILE"

docker compose \
    --env-file "$ENV_FILE" \
    up \
    --detach \
    --force-recreate \
    2>&1 | tee -a "$LOGFILE"

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    echo "ERROR: Docker Compose failed to start the containers." | tee -a "$LOGFILE"
    exit 1
fi

echo "============================================================" | tee -a "$LOGFILE"
echo "FULL Docker rebuild completed successfully." | tee -a "$LOGFILE"
echo "============================================================" | tee -a "$LOGFILE"
echo ""| tee -a "$LOGFILE"
echo "============================================================" | tee -a "$LOGFILE"
echo "Gebruik in de akeeba restore:" | tee -a "$LOGFILE"
echo "-----------------------------" | tee -a "$LOGFILE"
echo "- Database host       : mariadb en niet localhost"| tee -a "$LOGFILE"
echo "- Force SSL           : NONE; uitzetten voor de gehele site"| tee -a "$LOGFILE"
echo "- .htacces Handling   : Use default"| tee -a "$LOGFILE"
echo "- Generate new secret : Switch op NO"| tee -a "$LOGFILE"
echo ""| tee -a "$LOGFILE"
echo "============================================================" | tee -a "$LOGFILE"
