#!/bin/sh
set -e

BACKUP_CRON="${BACKUP_CRON:-0 */6 * * *}"
PRUNE_CRON="${PRUNE_CRON:-0 1 * * 0}"
HEALTH_PORT="${HEALTH_PORT:-8080}"

# Initialize restic repository on first run
if ! restic snapshots > /dev/null 2>&1; then
    echo "Initializing restic repository"
    restic init
fi

# Write crontab
printf '%s\n' \
    "$BACKUP_CRON /scripts/backup.sh >> /proc/1/fd/1 2>&1" \
    "$PRUNE_CRON /scripts/prune.sh >> /proc/1/fd/1 2>&1" \
    > /etc/crontabs/root

# Health endpoint — busybox httpd serves a CGI script
mkdir -p /srv/health/cgi-bin
cat > /srv/health/cgi-bin/health << 'HEALTHSCRIPT'
#!/bin/sh
UPTIME_SECONDS=$(awk '{print int($1)}' /proc/uptime)
HOURS=$((UPTIME_SECONDS / 3600))
MINUTES=$(((UPTIME_SECONDS % 3600) / 60))
printf 'Content-Type: application/json\r\n\r\n'
printf '{"status":"ok","pid":%d,"uptime":"%dh%dm"}\n' $$ "$HOURS" "$MINUTES"
HEALTHSCRIPT
chmod +x /srv/health/cgi-bin/health

# Start health endpoint in background
httpd -p "$HEALTH_PORT" -h /srv/health -c '/cgi-bin/*:*'

echo "gitea-backup ready — backup: $BACKUP_CRON, prune: $PRUNE_CRON"

# Run crond in foreground (PID 1)
exec crond -f -l 2
