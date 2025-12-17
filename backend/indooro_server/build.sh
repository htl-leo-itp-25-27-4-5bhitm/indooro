#!/usr/bin/env bash
mvn package -DskipTests
docker build --tag ghcr.io/htl-leo-itp-25-27-4-5bhitm/indooro-backend:latest --file src/main/docker/Dockerfile .

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/htl-leo-itp-25-27-4-5bhitm/indooro-backend:latest \
  --push \
  --file src/main/docker/Dockerfile \
  .
