#!/bin/bash
set -euxo pipefail

# --exclude keeps newtar's python3 from stomping our base image's python3.
# Possibly this is an indication we should exclude more layers, but ... it
# works?
tar -xzf /newtar.tar.gz --exclude /usr/bin/python3

chmod +x /etc/confluent/docker/run

set +x

# The untar above replaced this file with the real one
exec /etc/confluent/docker/run
