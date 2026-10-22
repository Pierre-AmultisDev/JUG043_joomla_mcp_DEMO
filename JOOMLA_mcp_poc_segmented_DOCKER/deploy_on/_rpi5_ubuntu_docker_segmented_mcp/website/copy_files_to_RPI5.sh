#!/usr/bin/env bash

RPI5_BASEPATH="ubuntu@RPi5-UB2404-001-WIRE:/home/ubuntu/docker/JOOMLA_mcp_poc_segm_web_DOCKER"
CONF_BASEPATH="../../../code"
ENV_BASEPATH="../env"

echo "[INFO   ] Copy files from windows -> rpi5 docker"
cd /mnt/c/@my_projects/_rpi5_joomla_mcp/JOOMLA_mcp_poc_segmented_DOCKER/deploy_on/_rpi5_docker_segmented_mcp/website/

echo "[INFO   ] Copy docker compose files"
rsync -avz ./docker-compose.yml "$RPI5_BASEPATH/"

echo "[INFO   ] Copy docker compose script files and docker containers"
rsync -avz ./compose_scripts/* "$RPI5_BASEPATH/"

echo "[INFO   ] Copy docker containers"
#rsync -avz ./mcp-server/* "$RPI5_BASEPATH/mcp-server/"
rsync -avz ./mariadb/* "$RPI5_BASEPATH/mariadb/"
rsync -avz ./joomla-akeeba/* "$RPI5_BASEPATH/joomla-akeeba/"
#rsync -avz ./opencode/* "$RPI5_BASEPATH/opencode/"

# copy akeeba backup file and restore script
#rsync -avz ./akeeba/kickstart.php "$RPI5_BASEPATH/akeeba/"
#rsync -avz ./akeeba/*.jpa "$RPI5_BASEPATH/akeeba/"

#echo "[INFO   ] Copy python script files"
#rsync -avz "$CONF_BASEPATH"/py_app/*.py "$RPI5_BASEPATH/py_app/"
#rsync -avz "$CONF_BASEPATH"/py_app/repositories/*.py "$RPI5_BASEPATH/py_app/repositories/"

#echo "[INFO   ] Copy python config files"
#rsync -avz "$CONF_BASEPATH"/py_conf/_rpi5_docker/pyproject.toml "$RPI5_BASEPATH/py_conf/"
#rsync -avz "$CONF_BASEPATH"/py_conf/_rpi5_docker/uv.lock "$RPI5_BASEPATH/py_conf/"

echo "[INFO   ] Copy .env file"
rsync -avz "$ENV_BASEPATH/.env" "$RPI5_BASEPATH/env/"
