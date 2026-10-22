# opencode-container

Browser-chatinterface (OpenCode) die met de `mcp-server`-container praat, zodat
je de MCP-tools kunt uitproberen zonder Claude Code of een abonnement nodig
te hebben. Gebruikt de officiële `ghcr.io/anomalyco/opencode`-image, geen
eigen Dockerfile.

## Bestanden

- `opencode.json` — configureert de remote MCP-verbinding
  (`http://mcp-server:9100/mcp`, het **interne** Docker-netwerkadres, niet
  het externe `:9100`) en het standaardmodel (OpenCode Zen).
- `workspace/` — lege werkmap voor OpenCode's file tree. Niet relevant voor
  deze demo (we gebruiken alleen de chat + MCP-tools), maar OpenCode
  verwacht wel een werkmap om in te starten.

## Model: OpenCode Zen

Standaard staat `opencode/deepseek-v4-flash-free` ingesteld (provider
`opencode` = OpenCode Zen). Zen heeft een aantal gratis modellen; die
wisselen af en toe. Controleer wat nu beschikbaar is:

- in de UI met `/models`, of
- `curl https://opencode.ai/zen/v1/models`

Is het standaardmodel verdwenen, pas dan `"model"` in `opencode.json` aan
(formaat `opencode/<model-id>`).

**API-key:** maak die aan op <https://opencode.ai/auth> en zet 'm in `.env`
als `OPENCODE_API_KEY=...`. Volgens de Zen-documentatie vraagt de
aanmelding om betaalgegevens; de gratis modellen kosten niets, maar de
betaalmodellen worden per verzoek afgerekend. Voor leden die niets willen
betalen is Groq (`GROQ_API_KEY`, gratis tier zonder creditcard) een
alternatief: zet `"model": "groq/llama-3.3-70b-versatile"`.

Test vooraf of het gekozen gratis model de MCP-tools betrouwbaar aanroept;
dat verschilt per model.

## Gebruiken

Open in de browser: `http://<pi-hostnaam>:4096`

Je krijgt een chatinterface. Vraag bijvoorbeeld: *"Welke artikelen gaan over
bijeenkomst?"* — als het goed is roept OpenCode dan zelf de
`search_articles`-tool van de MCP-server aan.

Wil je in plaats van het gratis Groq-model liever de kwaliteit van Claude
laten zien? Zet dan (tijdelijk) `ANTHROPIC_API_KEY` in `.env` en wijzig
`"model"` in `opencode.json` naar bv. `"anthropic/claude-sonnet-4-6"` — mooi
om als contrast te tonen naast het gratis model.

## Let op

- **Niet getest tegen de echte image:** de service start `opencode web` via
  `command:` in docker-compose. Als de container meteen stopt, check
  `docker compose logs opencode` — mogelijk heeft de image een andere
  entrypoint en moet `command:` aangepast worden.
- **Geen wachtwoord:** poort 4096 is open voor iedereen op je netwerk. Zet
  voor de demo eventueel `OPENCODE_SERVER_PASSWORD` als environment-variabele.
- **Privacy:** chatvragen en tool-resultaten (dus ook ledengegevens uit
  `list_users`/`get_user`) gaan naar de cloudprovider (Groq). Anonimiseer de
  dump vóór de demo (zie `code/README.md`).

## Sessiegeschiedenis bewaren

OpenCode bewaart sessies, projecten en inloggegevens in `opencode/data/`
(gemount op `/data` in de container, via `XDG_DATA_HOME`/`XDG_STATE_HOME`).
Die map overleeft `docker compose down` en rebuilds. Wil je de geschiedenis
wissen, verwijder dan de inhoud van `opencode/data/` (behalve `.gitkeep`)
terwijl de container gestopt is.

Let op: `copy_files_to_RPI5.sh` kopieert deze map ook van je laptop naar de
Pi (zonder `--delete`). Zolang die map op je laptop leeg is, overschrijft dat
niets. Draai OpenCode dus niet ook lokaal met dezelfde map.
De data kan chatinhoud bevatten: gebruik `opencode/data/` niet in git.
