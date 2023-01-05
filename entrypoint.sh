#!/bin/sh

sudo chown $(id -u):$(id -g) "${GLSDK}/yocto-layers/build"
sudo chown $(id -u):$(id -g) "${GLSDK}/yocto-layers/downloads"

exec "$@"
