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

cp ../cmd .
tar -cvzf newtar.tar.gz newtar --transform='s/^newtar//g'
rm -rf newtar

cat > Dockerfile <<- EOF
FROM openjdk:18-jdk-buster

COPY newtar.tar.gz /newtar.tar.gz
COPY cmd /etc/confluent/docker/run

$(docker inspect ${confluent_image} | jq -r '.[0].ContainerConfig.Env[]'|sed 's/^/ENV /')

CMD /etc/confluent/docker/run
EOF

image_tag="honeycomb-${service}:${version}"

# Skip the actual build if we're on Github, because actions will take care of it
# for us, including push.
if [[ -z $github_build ]]; then
  # Assumes you have buildx installed, and `docker buildx ls` includes both
  # linux/amd64 and linux/arm64
  docker buildx create --platform=linux/arm64,linux/amd64 --use --name mybuilder

  if [[ "$(arch)" == "x86_64" ]]; then
    platform=${platform:-linux/amd64}
  else
    platform=${platform:-linux/amd64}
  fi

  # buildx --load currently only works with one platform. If we were using --push,
  # --platform would be a comma-separated list
  docker buildx build -t "${image_tag}" --platform=$platform --load .

  docker buildx rm mybuilder
fi
