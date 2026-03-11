# Contributing

This is a personal homelab project. Issues and PRs welcome but no guarantees on response time.

## Development

```bash
make build    # Build image
make run      # Run locally
make test     # Test health endpoint
make stop     # Stop container
```

## Releases

Push to `main` triggers GitHub Actions to build and publish to GHCR.
Tagged releases (`v*`) get semver tags.
