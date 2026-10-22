#!/usr/bin/env bash

RPI5_BASEPATH="ubuntu@RPi5-UB2404-001-WIRE:/home/ubuntu/docker/JOOMLA_mcp_poc_senso_web_DOCKER"
CONF_BASEPATH="../../../code"
ENV_BASEPATH="../env"

echo "[INFO   ] Copy files from windows -> rpi5 docker"
cd /mnt/c/@my_projects/Joomla/JUG043_joomla_mcp_DEMO/JOOMLA_mcp_poc_senso_DOCKER/deploy_on/_rpi5_ubuntu_docker_senso_mcp/website/

echo "[INFO   ] Copy docker compose files"
rsync -avz ./docker-compose.yml "$RPI5_BASEPATH/"

echo "[INFO   ] Copy docker compose script files and docker containers"
rsync -avz ./compose_scripts/*.sh "$RPI5_BASEPATH/"

echo "[INFO   ] Copy docker container(s)"
#rsync -avz ./mcp-server/* "$RPI5_BASEPATH/mcp-server/"
rsync -avz ./mariadb/* "$RPI5_BASEPATH/mariadb/"

echo "[INFO   ] Copy akeeba backup file and restore script"
rsync -avz ./joomla-akeeba/* "$RPI5_BASEPATH/joomla-akeeba/"

#echo "[INFO   ] Copy OpenCode files"
#rsync -avz ./opencode/opencode.json "$RPI5_BASEPATH/opencode/"
#rsync -avz ./opencode/README.md "$RPI5_BASEPATH/opencode/"

#echo "[INFO   ] Copy python script files"
#rsync -avz "$CONF_BASEPATH"/py_app/*.py "$RPI5_BASEPATH/py_app/"
#rsync -avz "$CONF_BASEPATH"/py_app/repositories/*.py "$RPI5_BASEPATH/py_app/repositories/"

#echo "[INFO   ] Copy python config files"
#rsync -avz "$CONF_BASEPATH"/py_conf/_rpi5_docker/pyproject.toml "$RPI5_BASEPATH/py_conf/"
#rsync -avz "$CONF_BASEPATH"/py_conf/_rpi5_docker/uv.lock "$RPI5_BASEPATH/py_conf/"

echo "[INFO   ] Copy .env file"
rsync -avz "$ENV_BASEPATH/.env" "$RPI5_BASEPATH/env/"
