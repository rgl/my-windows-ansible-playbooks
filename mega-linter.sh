#!/bin/bash
set -euo pipefail

image_name='oxsecurity/megalinter'
# see https://hub.docker.com/r/oxsecurity/megalinter/tags
# renovate: datasource=docker depName=oxsecurity/megalinter
image_version='8.4.2'

# see https://megalinter.io/latest/configuration/
# see https://megalinter.io/latest/descriptors/powershell/
# see https://megalinter.io/latest/descriptors/powershell_powershell/
# see https://github.com/PowerShell/PSScriptAnalyzer#readme
# see https://github.com/oxsecurity/megalinter#docker-container
# see https://github.com/oxsecurity/megalinter/blob/main/docs/descriptors/powershell_powershell.md
exec docker run \
    --rm \
    --net=host \
    -v "$PWD:/project:ro" \
    -v "$PWD/tmp/megalinter-reports:/megalinter-reports:rw" \
    -e DEFAULT_WORKSPACE=/project \
    -e REPORT_OUTPUT_FOLDER=/megalinter-reports \
    -e CLEAR_REPORT_FOLDER=true \
    -e GITHUB_ACTIONS \
    -e GITHUB_WORKFLOW \
    "$image_name:v$image_version"
