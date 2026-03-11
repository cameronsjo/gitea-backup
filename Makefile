# gitea-backup — Encrypted Gitea backup sidecar
IMAGE_NAME := ghcr.io/cameronsjo/gitea-backup
TAG := latest

.PHONY: help build run stop logs shell test clean

## Show available targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## //' | sort
	@echo ""
	@grep -E '^[a-zA-Z_-]+:' $(MAKEFILE_LIST) | awk -F ':' '{print "  " $$1}'

## Build the container image
build:
	docker build -t $(IMAGE_NAME):$(TAG) .

## Run locally with test environment (mount a test dir as /data)
run:
	@mkdir -p /tmp/gitea-backup-test
	docker run -d --name gitea-backup \
		-e RESTIC_REPOSITORY=/tmp/restic-repo \
		-e RESTIC_PASSWORD=test-password \
		-e TZ=America/Chicago \
		-v /tmp/gitea-backup-test:/data:ro \
		-p 8080:8080 \
		$(IMAGE_NAME):$(TAG)

## Stop and remove running container
stop:
	docker stop gitea-backup 2>/dev/null || true
	docker rm gitea-backup 2>/dev/null || true

## Tail container logs
logs:
	docker logs -f gitea-backup

## Shell into running container
shell:
	docker exec -it gitea-backup /bin/sh

## Test health endpoint (requires running container)
test:
	curl -sf http://localhost:8080/cgi-bin/health | head -1

## Remove built image
clean:
	docker rmi $(IMAGE_NAME):$(TAG) 2>/dev/null || true
