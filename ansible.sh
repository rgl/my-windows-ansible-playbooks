#!/bin/bash
set -euo pipefail

command="$(basename "$0" .sh)"
tag="ansible-$(basename "$PWD")"

# build the ansible image.
DOCKER_BUILDKIT=1 docker build -f Dockerfile.ansible -t "$tag" .

# execute command (e.g. ansible-playbook).
# NB the GITHUB_ prefixed environment variables are used to trigger ansible-lint
#    to annotate the GitHub Actions Workflow with the linting violations.
#    see https://github.com/ansible/ansible-lint/blob/v6.3.0/src/ansiblelint/app.py#L95
#    see https://ansible-lint.readthedocs.io/en/latest/usage/#ci-cd
exec docker run \
    --rm \
    --net=host \
    -v "$PWD:/playbooks:ro" \
    -e GITHUB_ACTIONS \
    -e GITHUB_WORKFLOW \
    "$tag" \
    "$command" \
    "$@"
