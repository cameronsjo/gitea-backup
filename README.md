# gitea-backup

Lightweight sidecar container that creates encrypted, consistent backups of
Gitea data to Azure Blob Storage using restic.

## What It Does

- Backs up Gitea data (repos, SQLite DB, config, SSH keys) every 6 hours
- Uses `sqlite3 .backup` for database consistency before snapshotting
- Encrypts everything client-side with restic (AES-256)
- Prunes old snapshots weekly (7 daily, 4 weekly, 12 monthly retention)
- Sends Discord notifications on success/failure
- Exposes `/cgi-bin/health` endpoint for container orchestration

## Environment Variables

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `AZURE_ACCOUNT_NAME` | Yes | — | Azure storage account |
| `AZURE_ACCOUNT_KEY` | Yes | — | Azure storage key |
| `RESTIC_REPOSITORY` | Yes | — | e.g. `azure:gitea-backup:` |
| `RESTIC_PASSWORD` | Yes | — | Restic encryption key |
| `DISCORD_WEBHOOK_URL` | No | — | Discord webhook for notifications |
| `BACKUP_CRON` | No | `0 */6 * * *` | Backup schedule |
| `PRUNE_CRON` | No | `0 1 * * 0` | Prune schedule (Sunday 1 AM) |
| `RETENTION_DAILY` | No | `7` | Daily snapshots to keep |
| `RETENTION_WEEKLY` | No | `4` | Weekly snapshots to keep |
| `RETENTION_MONTHLY` | No | `12` | Monthly snapshots to keep |
| `GITEA_DB_PATH` | No | `/data/gitea/gitea.db` | Path to Gitea SQLite DB |
| `TZ` | No | `UTC` | Timezone |

## Restore

```bash
# List snapshots
export AZURE_ACCOUNT_NAME="..." AZURE_ACCOUNT_KEY="..." RESTIC_REPOSITORY="azure:gitea-backup:" RESTIC_PASSWORD="..."
restic snapshots

# Restore latest
restic restore latest --target /tmp/gitea-restore
```

## Health Endpoint

`GET :8080/cgi-bin/health` returns JSON:

```json
{"status": "ok", "pid": 1, "uptime": "3h42m"}
```
