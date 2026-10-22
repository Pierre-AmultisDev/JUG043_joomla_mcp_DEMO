:: =============================================================================
::
:: @package    JUG043_joomla_mcp_DEMO
:: @container  Joomla MCP POC
:: @name       start_all_containers.cmd
:: @purpose    Shell script to start building all containers/services defined in dockercompose.yml
:: @version    v0.0.4  2026-10-22
::
:: =============================================================================

powershell -ExecutionPolicy Bypass -File .\start_all_containers.ps1
