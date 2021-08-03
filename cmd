#!/bin/bash
set -euo pipefail

tar -xzvf /newtar.tar.gz

chmod +x /etc/confluent/docker/run

# The untar above replaced this file with the real one
exec /etc/confluent/docker/run
