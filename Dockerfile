FROM alpine:3.21

LABEL org.opencontainers.image.source="https://github.com/cameronsjo/gitea-backup"
LABEL org.opencontainers.image.description="Encrypted Gitea backup sidecar — restic to Azure Blob Storage"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache \
    restic \
    sqlite \
    curl \
    busybox-extras \
    tzdata

COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

ENV HEALTH_PORT=8080
ENV BACKUP_CRON="0 */6 * * *"
ENV PRUNE_CRON="0 1 * * 0"
ENV GITEA_DB_PATH="/data/gitea/gitea.db"
ENV RETENTION_DAILY=7
ENV RETENTION_WEEKLY=4
ENV RETENTION_MONTHLY=12

EXPOSE 8080/tcp

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q --spider http://127.0.0.1:${HEALTH_PORT}/cgi-bin/health || exit 1

# Runs as root: Alpine crond requires root for /etc/crontabs/root,
# and busybox httpd needs root to bind port 8080 at startup.
# The container has no shell access exposed — acceptable trade-off.
ENTRYPOINT ["/scripts/entrypoint.sh"]
