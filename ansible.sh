#!/bin/bash
set -euo pipefail

command="$(basename "$0" .sh)"
tag="ansible-$(basename "$PWD")"

# build the ansible image.
DOCKER_BUILDKIT=1 docker build -f Dockerfile.ansible -t "$tag" .

# execute command (e.g. ansible-playbook).
exec docker run --rm --net=host -v "$PWD:/playbooks:ro" "$tag" "$command" "$@"
