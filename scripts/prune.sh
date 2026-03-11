#!/bin/sh
set -e

RETENTION_DAILY="${RETENTION_DAILY:-7}"
RETENTION_WEEKLY="${RETENTION_WEEKLY:-4}"
RETENTION_MONTHLY="${RETENTION_MONTHLY:-12}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Starting restic prune at $TIMESTAMP"

restic forget \
    --keep-daily "$RETENTION_DAILY" \
    --keep-weekly "$RETENTION_WEEKLY" \
    --keep-monthly "$RETENTION_MONTHLY" \
    --prune \
    --verbose 2>&1

echo "Prune complete at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
