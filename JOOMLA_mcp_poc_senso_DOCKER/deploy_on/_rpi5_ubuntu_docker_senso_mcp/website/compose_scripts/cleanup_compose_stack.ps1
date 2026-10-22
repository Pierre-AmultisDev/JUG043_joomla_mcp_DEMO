# =============================================================================
#
# @package    JUG043_joomla_mcp_DEMO
# @container  Joomla MCP PoC
# @name       clenup_compose_stack.ps1
# @purpose    PowerShell script to stop the stack defined in dockercompose.yml and remove everything related to it
# @version    v0.0.1  2026-10-22
# @author     pierre@amultis.dev
# @copyright  (C) Pierre Veelen
#
# =============================================================================
$EnvFile = "..\..\env\.env"

$ExternalNetworkName = "external-mcp-senso-net"

# https://docs.docker.com/reference/cli/docker/compose/config/
# --quiet       alleen valideren, niets tonen
docker compose --env-file $EnvFile config --quiet
if ($LASTEXITCODE -eq 0) {

    # https://docs.docker.com/reference/cli/docker/compose/down/
    # Stopt en verwijdert de containers en netwerken van deze stack, plus:
    # --volumes         ook named volumes en anonieme volumes verwijderen (DATA GAAT VERLOREN!)
    # --rmi all         alle images verwijderen die door de services worden gebruikt (gebouwd en gepulled)
    # --remove-orphans  ook containers verwijderen die niet meer in de compose file staan
    Write-Host "Stoppen en verwijderen van containers, netwerken, volumes en images..."
    docker compose --env-file $EnvFile down --volumes --rmi all --remove-orphans

    # Ruim de dangling images (<none>) op die achterblijven van eerdere builds
    # en de build cache. Let op: de build cache is gedeeld met andere projecten.
    Write-Host "Opruimen van dangling images en build cache..."
    docker image prune --force
    docker builder prune --force
	
	Write-Host "Opruimen van '$ExternalNetworkName' proberen..."
    docker network rm $ExternalNetworkName

    Write-Host "Klaar. De stack is volledig verwijderd."
}
else {
    Write-Host "Docker compose config file validation failed. Did nothing further"
}
