#!/bin/sh

mkdir -p /dev/net
mknod /dev/net/tun c 10 200
mknod /dev/net/tun0 c 10 200
