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

# Step 2: Single restic snapshot — everything in /data (excluding live DB + transient SQLite files) plus consistent DB copy
if [ -f "$DB_COPY" ]; then
    restic backup /data "$DB_COPY" \
        --exclude "$GITEA_DB_PATH" \
        --exclude "${GITEA_DB_PATH}-journal" \
        --exclude "${GITEA_DB_PATH}-wal" \
        --exclude "${GITEA_DB_PATH}-shm" \
        --verbose --tag gitea 2>&1 || EXIT_CODE=$?
    rm -f "$DB_COPY"
else
    restic backup /data \
        --exclude "${GITEA_DB_PATH}-journal" \
        --exclude "${GITEA_DB_PATH}-wal" \
        --exclude "${GITEA_DB_PATH}-shm" \
        --verbose --tag gitea 2>&1 || EXIT_CODE=$?
fi

# Restic exit codes: 0=success, 1=fatal, 3=warnings (incomplete snapshot)
# Exit 3 means snapshot was created but some files were unreadable (transient files vanishing mid-scan).
# Treat as success since the consistent DB copy is what matters.
if [ "$EXIT_CODE" -eq 3 ]; then
    echo "Warning: restic reported warnings (exit 3), treating as success"
    EXIT_CODE=0
fi

# Step 3: Notify
# DISCORD_NOTIFY_ON_SUCCESS=false suppresses the success post only; failures
# always post. Only silence success where a staleness monitor would catch a
# job that stops running altogether.
NOTIFY_ON_SUCCESS="${DISCORD_NOTIFY_ON_SUCCESS:-true}"
if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    if [ "$EXIT_CODE" -eq 0 ] && [ "$NOTIFY_ON_SUCCESS" = "false" ]; then
        echo "Backup succeeded; success notification suppressed (DISCORD_NOTIFY_ON_SUCCESS=false)"
    elif [ "$EXIT_CODE" -eq 0 ]; then
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
