-- Read-only databasegebruiker voor de MCP-server.
-- Dit script draait automatisch bij de EERSTE start van de mariadb-container
-- (alleen wanneer het data-volume nog leeg is).
--
-- LET OP: dit bestand ondersteunt GEEN variabele-substitutie vanuit .env.
-- Als je het wachtwoord of de databasenaam hieronder aanpast, zorg dan dat
-- dit overeenkomt met MCP_READER_PASSWORD en MYSQL_DATABASE in je .env.

CREATE USER IF NOT EXISTS 'mcp_reader'@'%' IDENTIFIED BY 'joomlamcpreader';
GRANT SELECT ON `joomla`.* TO 'mcp_reader'@'%';
FLUSH PRIVILEGES;
