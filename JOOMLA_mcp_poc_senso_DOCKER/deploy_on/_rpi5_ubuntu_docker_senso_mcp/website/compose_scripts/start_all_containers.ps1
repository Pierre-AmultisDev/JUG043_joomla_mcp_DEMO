# =============================================================================
#
# @package    JUG043_joomla_mcp_DEMO
# @container  Joomla MCP PoC
# @name       start_all_containers.ps1
# @purpose    PowerShell script to start building all containers/services defined in dockercompose.yml
# @version    v0.0.4  2026-10-22
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

    # https://docs.docker.com/reference/cli/docker/compose/up/
    # --build     rebuild if need be
    # --progress  plain No escape codes / no colors
    # --detach    start containers in background
    $null = Invoke-Logged "docker compose --env-file `"$EnvFile`" up --build --detach"

}
else {
    Write-Host "Docker compose config file validation failed. Did nothing further"
}
