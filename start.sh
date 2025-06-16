#!/bin/sh

if [ "$ENABLE_IPv6" -eq 0 ]; then
    IPv6_FLAGS="--pull-filter ignore route-ipv6 --pull-filter ignore ifconfig-ipv6"
fi

( openvpn --client \
          --auth-nocache \
          --auth-retry nointeract \
          --connect-retry-max 32 \
          $IPv6_FLAGS \
          --up-restart \
          --cd /internal-config \
          --config "$CONFIG_FILE_NAME" \
          $EXTRA_OPENVPN_FLAGS \
) &
OPENVPN_PID=$!

if [ "$ENABLE_SOCKS_PROXY" -eq 1 ]; then
    until ip link show tun0 2>&1 | grep -qv "does not exist"; do
        sleep 1
        kill -0 "$OPENVPN_PID" 2>/dev/null || exit 1
    done
    sockd -f /internal-config/sockd.conf
else
    wait $OPENVPN_PID
    exit $?
fi
