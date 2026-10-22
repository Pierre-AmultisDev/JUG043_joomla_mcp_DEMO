# =============================================================================
#
# @package    JUG043_joomla_mcp_DEMO
# @container  Joomla MCP POC
# @name       rebuild_and_start_all_containers.ps1
# @purpose    Fully rebuild and start all Docker containers/services
# @version    v0.0.4  2026-10-22
#
# =============================================================================

$LogFile = "docker_build_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/#use-the-env_file-attribute
# Using an .env file lets you use the same file for use by a plain docker run --env-file ... command,
# or to share the same .env file within multiple services without the need to duplicate a long environment YAML block.
$EnvFile = "..\..\env\.env"

$ExternalNetworkName = "external-mcp-segmented-net"

# =============================================================================
# Helper functies
# =============================================================================

# Toon tekst op scherm en voeg toe aan het logbestand (tee)
function Write-Log {
    param([string]$Message = "")
    Write-Host $Message
    Add-Content -Path $LogFile -Value $Message -Encoding UTF8
}

# Voer een opdracht uit via cmd, toon de output live en voeg toe aan het logbestand.
# Geeft de exitcode van de opdracht terug (vervanger van PIPESTATUS).
function Invoke-Logged {
    param([string]$Command)
    cmd /c "$Command 2>&1" | ForEach-Object {
        Write-Host $_
        Add-Content -Path $LogFile -Value $_ -Encoding UTF8
    }
    return $LASTEXITCODE
}

# =============================================================================
# Check network
# =============================================================================
Write-Host "Controleren of Docker netwerk '$ExternalNetworkName' bestaat..."

# Controleer of de netwerknaam exact voorkomt in de lijst van Docker
$networks = docker network ls --format '{{.Name}}'
if ($networks -contains $ExternalNetworkName) {
    Write-Host "[INFO] Het netwerk '$ExternalNetworkName' bestaat al. We gaan verder..."
}
else {
    Write-Host "[OK] Netwerk niet gevonden. Aanmaken van '$ExternalNetworkName'..."
    docker network create $ExternalNetworkName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Netwerk kon niet worden aangemaakt."
        exit 1
    }
}

# Hier gaat je script gewoon verder
Write-Host "`n[STATUS] Klaar! Je kunt nu docker-compose up starten."

# =============================================================================
# Check environment file
# =============================================================================
if (-not (Test-Path -Path $EnvFile -PathType Leaf)) {
    Write-Host "ERROR: Environment file not found: $EnvFile"
    exit 1
}

Write-Host "Using environment file: $EnvFile"
Set-Content -Path $LogFile -Value "Using environment file: $EnvFile" -Encoding UTF8

# =============================================================================
# Validate Docker Compose configuration
# =============================================================================
docker compose --env-file $EnvFile config --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Log "Docker Compose configuration is valid."
}
else {
    Write-Log "ERROR: Docker Compose configuration validation failed."
    exit 1
}

# =============================================================================
# Full rebuild
# =============================================================================
Write-Log "Starting FULL Docker rebuild..."

# verwijder joomla-www helemaal. Installatie script moet folder aanmaken.
# anders kan daar niet in geschreven worden.
if (Test-Path -Path ".\joomla-www") {
    Remove-Item -Path ".\joomla-www" -Recurse -Force
}

$rc = Invoke-Logged "docker compose --env-file `"$EnvFile`" --progress=plain build --no-cache --pull"
if ($rc -ne 0) {
    Write-Log "ERROR: Docker image build failed."
    exit 1
}

# =============================================================================
# Recreate containers
# =============================================================================
Write-Log "Recreating containers..."

$rc = Invoke-Logged "docker compose --env-file `"$EnvFile`" up --detach --force-recreate"
if ($rc -ne 0) {
    Write-Log "ERROR: Docker Compose failed to start the containers."
    exit 1
}

Write-Log "============================================================"
Write-Log "FULL Docker rebuild completed successfully."
Write-Log "============================================================"
Write-Log ""
