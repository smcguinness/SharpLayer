#!/bin/bash -x

set -e

rm -rf layer && mkdir -p layer/sharp/lib
docker build -t node10x-sharp-builder -f Dockerfile .

docker run --rm -v $PWD/layer/sharp:/var/task node10x-sharp-builder sh -c "mkdir -p nodejs && cd nodejs && LD_LIBRARY_PATH=opt/lib npm install sharp"

CONTAINER=$(docker run -d node10x-sharp-builder false)
docker cp \
    $CONTAINER:/var/task/lib/. \
    layer/sharp/lib/.

docker rm $CONTAINER
