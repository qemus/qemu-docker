#!/usr/bin/env bash
set -e

docker build --tag qemu .
docker images qemu:latest --format "{{.Repository}}:{{.Tag}} -> {{.Size}}"
docker run --rm -it --name qemu --device="/dev/kvm" --cap-add NET_ADMIN -p 22:22 docker.io/library/qemu

