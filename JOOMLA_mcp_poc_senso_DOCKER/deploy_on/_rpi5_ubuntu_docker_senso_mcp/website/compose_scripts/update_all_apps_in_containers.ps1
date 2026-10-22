# =============================================================================
#
# @package    JUG043_joomla_mcp_DEMO
# @container  Joomla MCP PoC
# @name       update_all_apps_in_containers.ps1
# @purpose    PowerShell script to rebuild and update all containers/services defined in dockercompose.yml
# @version    v0.0.3  2026-09-24
# @author     pierre@amultis.dev
# @copyright  (C) Pierre Veelen
#
# =============================================================================
$LogFile = "docker_build_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/#use-the-env_file-attribute
# Using an .env file lets you use the same file for use by a plain docker run --env-file ... command,
# or to share the same .env file within multiple services without the need to duplicate a long environment YAML block.
$EnvFile = "..\..\env\.env"

# Voer een opdracht uit via cmd, toon de output live en voeg toe aan het logbestand (tee).
# Geeft de exitcode van de opdracht terug.
function Invoke-Logged {
    param([string]$Command)
    cmd /c "$Command 2>&1" | ForEach-Object {
        Write-Host $_
        Add-Content -Path $LogFile -Value $_ -Encoding UTF8
    }
    return $LASTEXITCODE
}

# https://docs.docker.com/reference/cli/docker/compose/config/
# --quiet       only validate the configuration, don't print anything
docker compose --env-file $EnvFile config --quiet
if ($LASTEXITCODE -eq 0) {

    # https://docs.docker.com/reference/cli/docker/compose/pull/
    # Haal de laatste versie op van alle services die een "image:" gebruiken
    # (dus geen eigen Dockerfile/build-sectie hebben, zoals bv. Uptime Kuma)
    Write-Host "Ophalen van laatste images voor services zonder build-sectie..."
    docker compose --env-file $EnvFile pull

    # https://docs.docker.com/reference/cli/docker/compose/build/
    # --progress  plain No escape codes / no colors
    # --no-cache  negeer alle layer cache, elke stap wordt opnieuw uitgevoerd
    # --pull      haal altijd de laatste base images op i.p.v. lokale kopie
    # (Bouwt alleen services die in dockercompose.yml een "build:" sectie hebben;
    #  services die alleen "image:" gebruiken worden hierboven al bijgewerkt)
    $null = Invoke-Logged "docker compose --env-file `"$EnvFile`" --progress=plain build --no-cache --pull"

    # https://docs.docker.com/reference/cli/docker/compose/up/
    # --detach    start containers in background
    docker compose --env-file $EnvFile up --detach

    # https://docs.docker.com/reference/cli/docker/image_prune/
    # Ruim alle ongebruikte images (ook oude getagde versies) en hun layers op
    # die zijn achtergebleven door de --no-cache build hierboven.
    # 
    # Let op: docker image prune -af verwijderd alles ook van andere stacks!
    # -f          geen bevestiging vragen
    # -a          ook ongebruikte getagde images verwijderen, niet alleen dangling
    Write-Host  "Opruimen van oude, ongebruikte images en layers..."
    docker image prune
    docker builder prune

}
else {
    Write-Host "Docker compose config file validation failed. Did nothing further"
}
