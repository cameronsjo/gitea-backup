#!/bin/sh
set -e

GITEA_DB_PATH="${GITEA_DB_PATH:-/data/gitea/gitea.db}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DB_COPY="/tmp/gitea.db"
EXIT_CODE=0

echo "Starting Gitea backup at $TIMESTAMP"

# Step 1: Create consistent SQLite copy
if [ -f "$GITEA_DB_PATH" ]; then
    echo "Creating consistent SQLite backup"
    sqlite3 "$GITEA_DB_PATH" ".backup '$DB_COPY'"
else
    echo "Warning: SQLite database not found at $GITEA_DB_PATH, skipping DB copy"
fi

# Step 2: Single restic snapshot — everything in /data (excluding live DB) plus consistent DB copy
if [ -f "$DB_COPY" ]; then
    restic backup /data "$DB_COPY" \
        --exclude "$GITEA_DB_PATH" \
        --verbose --tag gitea 2>&1 || EXIT_CODE=$?
    rm -f "$DB_COPY"
else
    restic backup /data --verbose --tag gitea 2>&1 || EXIT_CODE=$?
fi

# Step 3: Notify
if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    if [ "$EXIT_CODE" -eq 0 ]; then
        curl -sf -H "Content-Type: application/json" -d "{
            \"username\": \"Gitea Backup\",
            \"avatar_url\": \"https://about.gitea.com/gitea.png\",
            \"embeds\": [{
                \"title\": \"Backup completed\",
                \"color\": 3066993,
                \"description\": \"Gitea data backed up to Azure\",
                \"footer\": {\"text\": \"$TIMESTAMP\"}
            }]
        }" "$DISCORD_WEBHOOK_URL" > /dev/null 2>&1 || true
    else
        curl -sf -H "Content-Type: application/json" -d "{
            \"username\": \"Gitea Backup\",
            \"avatar_url\": \"https://about.gitea.com/gitea.png\",
            \"embeds\": [{
                \"title\": \"Backup FAILED\",
                \"color\": 15158332,
                \"description\": \"Gitea backup failed — check docker logs gitea-backup\",
                \"footer\": {\"text\": \"$TIMESTAMP\"}
            }]
        }" "$DISCORD_WEBHOOK_URL" > /dev/null 2>&1 || true
    fi
fi

exit $EXIT_CODE
