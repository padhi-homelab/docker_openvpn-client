#!/bin/sh

if [ $ENABLE_IPv6 -eq 0 ]; then
    EXTRA_FLAGS="--pull-filter ignore route-ipv6 --pull-filter ignore ifconfig-ipv6"
fi

openvpn --client \
        --auth-nocache \
        --auth-retry nointeract \
        --connect-retry-max 32 \
        $EXTRA_FLAGS \
        --up-restart \
        --cd /internal-config \
        --config $CONFIG_FILE_NAME \
        &

until ip link show tun0 2>&1 | grep -qv "does not exist"; do
    sleep 1
done

sockd -f /internal-config/sockd.conf
