#!/bin/sh

cp -r /config /internal-config
mv /sockd.conf /internal-config/

sed -i \
    -e 's/#.*$//' \
    -e '/up /c up \/etc\/openvpn\/up.sh' \
    -e '/down /c down \/etc\/openvpn\/down.sh' \
    -e 's/^proto udp$/proto udp4/' \
    -e 's/^proto tcp$/proto tcp4/' \
    /internal-config/$CONFIG_FILE_NAME

if [ -z "${ENTRYPOINT_RUN_AS_ROOT:-}" ]; then
    chown -R ${DOCKER_USER}:${DOCKER_USER} /internal-config
fi

chmod og-rwx /internal-config/*
