#!/bin/sh

openvpn --client \
        --auth-nocache \
        --connect-retry-max 10 \
        --pull-filter ignore "route-ipv6" \
        --pull-filter ignore "ifconfig-ipv6" \
        --up-restart \
        --cd /internal-config \
        --config $CONFIG_FILE_NAME \
        &

until ip link show tun0 2>&1 | grep -qv "does not exist"; do
    sleep 1
done

sockd -f /internal-config/sockd.conf
