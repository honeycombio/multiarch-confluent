#!/bin/bash
set -euo pipefail
set -x
service=${1-}
version=$2
if ! [[ "$service" == "zookeeper" || "$service" == "kafka" ]]; then
    echo "Not recognized."
    exit 1
fi
rm -r $service || true
mkdir -p $service
cd $service
confluent_image="confluentinc/cp-$service:$version"
# _Always_ amd64 even if builder is on arm64
docker pull --platform linux/amd64 "$confluent_image"
docker save "$confluent_image" | tar -x
# We do not want the first layer; we want layers >=1 (if zero-indexed), so
# tail -n +2 (1-indexed)
layers=$(cat manifest.json \
    | jq -r '.[0].Layers[]' \
    | tail -n +2)
mkdir newtar; cd newtar
for l in $layers; do
    tar -xf ../$l
done
cd -
tar -cvzf newtar.tar.gz newtar --transform='s/^newtar//g'
cat > Dockerfile <<- EOF
FROM openjdk:18-jdk-buster
COPY newtar.tar.gz /newtar.tar.gz
# RUN tar -xzvf /newtar.tar.gz
RUN mkdir -p /etc/confluent/docker
RUN echo 'tar -xzvf /newtar.tar.gz ; chmod +x /etc/confluent/docker/run; exec /etc/confluent/docker/run' > /etc/confluent/docker/run; chmod +x /etc/confluent/docker/run

$(docker inspect ${confluent_image} | jq -r '.[0].ContainerConfig.Env[]'|sed 's/^/ENV /')
#ENV CONFLUENT_PLATFORM_LABEL=
#ENV CONFLUENT_VERSION=5.5.1
#ENV CONFLUENT_DEB_VERSION=1
#ENV ZULU_OPENJDK_VERSION=8=8.38.0.13
#ENV LANG=C.UTF-8
#ENV CUB_CLASSPATH=/etc/confluent/docker/docker-utils.jar
#ENV COMPONENT=zookeeper
CMD /etc/confluent/docker/run
EOF

docker build -t "test-$service" .
