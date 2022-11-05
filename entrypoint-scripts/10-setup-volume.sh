#!/bin/sh

cp -r /config /internal-config
mv /sockd.conf /internal-config/

sed -i \
    -e 's/#.*//' \
    -e 's/^up .*//' \
    -e 's/^down .*//' \
    -e 's/^script-security .*//' \
    /internal-config/$CONFIG_FILE_NAME

echo 'script-security 2' >> /internal-config/$CONFIG_FILE_NAME
echo 'up /etc/openvpn/up.sh' >> /internal-config/$CONFIG_FILE_NAME
echo 'down /etc/openvpn/down.sh' >> /internal-config/$CONFIG_FILE_NAME

if [ -z "${ENTRYPOINT_RUN_AS_ROOT:-}" ]; then
    chown -R ${DOCKER_USER}:${DOCKER_GROUP} /internal-config
fi

chmod og-rwx /internal-config/*
