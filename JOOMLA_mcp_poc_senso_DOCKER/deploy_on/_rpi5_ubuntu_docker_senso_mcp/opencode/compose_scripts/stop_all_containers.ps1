# =============================================================================
#
# @package    JUG043_joomla_mcp_DEMO
# @container  Joomla MCP PoC
# @name       stop_all_containers.ps1
# @purpose    PowerShell script to stop all containers/services defined in dockercompose.yml
# @version    v0.0.4  2026-10-22
# @author     pierre@amultis.dev
# @copyright  (C) Pierre Veelen
#
# =============================================================================
# https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/#use-the-env_file-attribute
# Using an .env file lets you use the same file for use by a plain docker run --env-file ... command,
# or to share the same .env file within multiple services without the need to duplicate a long environment YAML block.
$EnvFile = "..\..\env\.env"

docker compose --env-file $EnvFile down
