FROM python:3.13-slim

# curl installeren om testen te kunnen uitvoeren
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# uv-binary uit de officiele uv-image kopieren (geen aparte install-stap
# nodig). Werkt op arm64 (Pi 5) net zo goed als op amd64.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

WORKDIR /app

# Deze paden zijn relatief aan de build-context "./" (de bovenliggende map), zoals
# gezet in docker-compose.yml. Op de RPi5 is dat de platte structuur die
# copy_files_to_RPI5.sh hier neerzet: py_app/, py_conf/, enz. direct naast
# deze Dockerfile.
COPY ./py_conf/pyproject.toml py_conf/uv.lock ./

# --locked: faalt hard als pyproject.toml en uv.lock niet meer synchroon
# lopen, in plaats van in dat geval stilzwijgend een ander versiesetje te
# installeren dan wat je lokaal getest hebt.
# --no-install-project: er is geen eigen package om te bouwen/installeren,
# alleen de dependencies uit pyproject.toml/uv.lock.
RUN uv sync --locked --no-install-project

# code/py_app wordt het "app"-package in de container (app/, met __init__.py)
COPY ./py_app/ ./app/

COPY ./mcp-server/docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# De venv die "uv sync" aanmaakt (/app/.venv) vooraan op PATH, zodat
# "python" in docker-entrypoint.sh de juiste, met uv geinstalleerde
# interpreter + dependencies gebruikt.
ENV PATH="/app/.venv/bin:${PATH}"

EXPOSE 8000

ENTRYPOINT ["/app/docker-entrypoint.sh"]
