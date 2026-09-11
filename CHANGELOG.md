# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed

- Reap orphaned health-check CGI processes instead of accumulating zombies under `crond`.

### Added

- Initial release: restic backup sidecar for Gitea
- SQLite `.backup` for database consistency
- Discord webhook notifications on success/failure
- Configurable cron schedule and retention policy
- Health endpoint via busybox httpd
