#!/usr/bin/env bash
# =============================================================================
# anonymize_members.sh
#
# Anonimiseert persoonsgegevens van leden in de Joomla-kopie, zodat het niet
# uitmaakt welk (cloud)model of welke client de MCP-server gebruikt.
#
# Draai dit op de Pi, NADAT de Joomla-kopie is hersteld (Akeeba/dump) en
# VOORDAT je de demo doet. De bewerking is ONOMKEERBAAR (op de kopie).
#
#   ./anonymize_members.sh --report   alleen tellen/controleren, niets wijzigen
#   ./anonymize_members.sh            anonimiseren (vraagt om bevestiging)
#   ./anonymize_members.sh --yes      anonimiseren zonder vraag
#
# Wat gebeurt er (alleen voor gebruikers die NIET behouden worden):
#   users         : name -> "Lid <id>", username -> "lid<id>",
#                   email -> "lid<id>@example.invalid", wachtwoord onbruikbaar
#   verwijderd    : profielvelden, notities, MFA-gegevens, custom-veldwaarden
#                   van die gebruikers
#   voor iedereen : sessies, "onthoud mij"-sleutels, activiteitenlog
#                   (bevat gebruikersnamen + IP-adressen), privéberichten,
#                   privacyverzoeken/-toestemmingen; created_by_alias leeg
#
# Standaard blijven Super Users ongemoeid (anders kun je niet meer inloggen).
# Wil je ook die anonimiseren: ANONYMIZE_INCLUDE_SUPERUSERS=1 ./anonymize_members.sh
#
# NIET afgedekt: namen/e-mailadressen die als vrije tekst in artikelen staan.
# Het --report-overzicht telt e-mailadressen in artikelen zodat je dat kunt
# nalopen.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-${SCRIPT_DIR}/../../env/.env}"
MARIADB_CONTAINER="${MARIADB_CONTAINER:-joomla-mariadb-segmented}"

MODE="run"
ASSUME_YES="no"
for arg in "$@"; do
  case "$arg" in
    --report) MODE="report" ;;
    --yes)    ASSUME_YES="yes" ;;
    -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
    *) echo "Onbekende optie: $arg" >&2; exit 2 ;;
  esac
done

# --- .env uitlezen (bewust niet via "source": waarden mogen spaties/$ bevatten)
get_env() {
  [ -f "$ENV_FILE" ] || return 0
  local v
  v="$(grep -E "^$1=" "$ENV_FILE" | head -1 | cut -d= -f2- || true)"
  v="${v%$'\r'}"; v="${v%\"}"; v="${v#\"}"; v="${v%\'}"; v="${v#\'}"
  printf '%s' "$v"
}

DB_NAME="${MYSQL_DATABASE:-$(get_env MYSQL_DATABASE)}"
ROOT_PW="${MYSQL_ROOT_PASSWORD:-$(get_env MYSQL_ROOT_PASSWORD)}"
P="${DB_TABLE_PREFIX:-$(get_env DB_TABLE_PREFIX)}"
P="${P:-jos_}"

# --- Hoe praten we met MariaDB? MARIADB_CMD is een override (voor testen).
if [ -n "${MARIADB_CMD:-}" ]; then
  # shellcheck disable=SC2206
  MYSQL=($MARIADB_CMD)
else
  [ -n "$DB_NAME" ] && [ -n "$ROOT_PW" ] || {
    echo "MYSQL_DATABASE/MYSQL_ROOT_PASSWORD niet gevonden in $ENV_FILE" >&2; exit 1; }
  MYSQL=(docker exec -i -e MYSQL_PWD="$ROOT_PW" "$MARIADB_CONTAINER" mariadb -uroot "$DB_NAME")
fi

sql()  { "${MYSQL[@]}" -N -B -e "$1"; }
sqlx() { "${MYSQL[@]}"; }   # SQL via stdin

table_exists() {
  [ "$(sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='${P}$1'")" = "1" ]
}
col_exists() {
  [ "$(sql "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='${P}$1' AND column_name='$2'")" = "1" ]
}

table_exists users || {
  echo "Tabel ${P}users niet gevonden in database '${DB_NAME:-?}'." >&2
  echo "Staat DB_TABLE_PREFIX goed in .env (nu: '${P}'), en is de Joomla-kopie al hersteld?" >&2
  exit 1; }

# --- Welke gebruikers blijven ongemoeid?
if [ "${ANONYMIZE_INCLUDE_SUPERUSERS:-0}" = "1" ] || ! table_exists user_usergroup_map || ! table_exists usergroups; then
  KEEP="SELECT 0"
else
  KEEP="SELECT m.user_id FROM \`${P}user_usergroup_map\` m JOIN \`${P}usergroups\` g ON g.id = m.group_id WHERE g.title = 'Super Users'"
fi

total="$(sql "SELECT COUNT(*) FROM \`${P}users\`")"
to_anon="$(sql "SELECT COUNT(*) FROM \`${P}users\` WHERE id NOT IN ($KEEP)")"
kept="$(sql "SELECT COUNT(*) FROM \`${P}users\` WHERE id IN ($KEEP)")"

echo "Database: ${DB_NAME:-(via MARIADB_CMD)}   Tabelprefix: ${P}"
echo "Gebruikers totaal: $total | te anonimiseren: $to_anon | behouden: $kept"
if [ "$kept" != "0" ]; then
  echo "Behouden (NIET geanonimiseerd, zichtbaar via list_users/get_user!):"
  sql "SELECT CONCAT('  - ', username, ' <', email, '>') FROM \`${P}users\` WHERE id IN ($KEEP)"
fi

pii_report() {
  echo "--- Controle op resterende persoonsgegevens ---"
  local real
  real="$(sql "SELECT COUNT(*) FROM \`${P}users\` WHERE email NOT LIKE '%@example.invalid'")"
  echo "Gebruikers met een niet-geanonimiseerd e-mailadres: $real"
  if table_exists content; then
    local n
    n="$(sql "SELECT COUNT(*) FROM \`${P}content\` WHERE CONCAT(IFNULL(introtext,''),' ',IFNULL(\`fulltext\`,'')) REGEXP '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}'")"
    echo "Artikelen met een e-mailadres in de tekst: $n  (handmatig nalopen)"
  fi
  if table_exists action_logs; then
    echo "Regels in activiteitenlog: $(sql "SELECT COUNT(*) FROM \`${P}action_logs\`")"
  fi
}

if [ "$MODE" = "report" ]; then
  pii_report
  echo "(--report: er is niets gewijzigd)"
  exit 0
fi

if [ "$ASSUME_YES" != "yes" ]; then
  echo
  echo "Dit wijzigt de database ONOMKEERBAAR. Typ ANONIMISEER om door te gaan:"
  read -r answer
  [ "$answer" = "ANONIMISEER" ] || { echo "Afgebroken."; exit 1; }
fi

echo "Anonimiseren..."

# 1) Gebruikers zelf
extra=""
col_exists users otpKey && extra="$extra, otpKey = ''"
col_exists users otep   && extra="$extra, otep = ''"
sqlx <<SQL
UPDATE \`${P}users\`
SET name = CONCAT('Lid ', id),
    username = CONCAT('lid', id),
    email = CONCAT('lid', id, '@example.invalid'),
    password = '!',
    activation = ''
    ${extra}
WHERE id NOT IN (${KEEP});
SQL

# 2) Persoonsgebonden rijen van die gebruikers
for spec in "user_profiles:user_id" "user_notes:user_id" "user_mfa:user_id"; do
  t="${spec%%:*}"; c="${spec##*:}"
  if table_exists "$t"; then
    sqlx <<SQL
DELETE FROM \`${P}${t}\` WHERE ${c} NOT IN (${KEEP});
SQL
    echo "  ${t}: opgeschoond"
  fi
done

# Custom-veldwaarden voor gebruikers (com_users.user)
if table_exists fields && table_exists fields_values; then
  sqlx <<SQL
DELETE v FROM \`${P}fields_values\` v
JOIN \`${P}fields\` f ON f.id = v.field_id
WHERE f.context = 'com_users.user' AND v.item_id NOT IN (${KEEP});
SQL
  echo "  fields_values (gebruikersvelden): opgeschoond"
fi

# 3) Tabellen die voor iedereen leeg mogen (sessies, logs, berichten, ...)
for t in session user_keys action_logs messages privacy_requests privacy_consents; do
  if table_exists "$t"; then
    sqlx <<SQL
DELETE FROM \`${P}${t}\`;
SQL
    echo "  ${t}: geleegd"
  fi
done

# 4) Auteursaliassen in artikelen
if table_exists content && col_exists content created_by_alias; then
  sqlx <<SQL
UPDATE \`${P}content\` SET created_by_alias = '' WHERE created_by_alias <> '';
SQL
  echo "  content.created_by_alias: leeggemaakt"
fi

echo "Klaar."
pii_report
