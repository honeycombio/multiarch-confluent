#!/bin/bash
set -euxo pipefail

# We should use this as the cmd, but, it calls /etc/confluent/docker/ensure,
# which fails with
# Error: Could not find or load main class .usr.share.java.cp-base-new.audience-annotations-0.5.0.jar
# Caused by: java.lang.ClassNotFoundException: /usr/share/java/cp-base-new/audience-annotations-0/5/0/jar
# And I'm not sure why; that file exists. Setting
# CLASSPATH=/usr/share/java/cp-base-new doesn't seem to help.
chmod +x /etc/confluent/docker/run

/etc/confluent/docker/configure
exec /etc/confluent/docker/launch
