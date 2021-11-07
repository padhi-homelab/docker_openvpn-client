#!/bin/sh

adduser -S -D -g "$PROXY_USERNAME" -H -h /dev/null "$PROXY_USERNAME"
echo "$PROXY_USERNAME:$PROXY_PASSWORD" | chpasswd 2> /dev/null
sed -i 's/socksmethod: none/socksmethod: username/' /internal-config/sockd.conf
