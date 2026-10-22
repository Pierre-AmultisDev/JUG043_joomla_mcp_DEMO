:: =============================================================================
::
:: @package    JUG043_joomla_mcp_DEMO
:: @container  Joomla MCP POC
:: @name       rebuild_and_start_all_containers.cmd
:: @purpose    Shell script to rebuild and update all containers/services defined in dockercompose.yml
:: @version    v0.0.4  2026-10-22
::
:: =============================================================================

powershell -ExecutionPolicy Bypass -File .\update_all_apps_in_containers.ps1
