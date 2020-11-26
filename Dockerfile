FROM padhihomelab/alpine-base:edge


ENV ENTRYPOINT_RUN_AS_ROOT=1

ENV CONFIG_FILE_NAME="client.conf"
ENV FORWARDED_PORTS=""


COPY 10-setup-volume.sh         /etc/docker-entrypoint.d/
COPY 20-setup-dev-tun.sh        /etc/docker-entrypoint.d/
COPY 30-setup-killswitch.sh     /etc/docker-entrypoint.d/


RUN chmod +x /etc/docker-entrypoint.d/* \
 && apk add --no-cache --update \
            bind-tools \
            openvpn


VOLUME [ "/config" ]

CMD openvpn --client \
            --auth-nocache \
            --connect-retry-max 10 \
            --pull-filter ignore "route-ipv6" \
            --pull-filter ignore "ifconfig-ipv6" \
            --up-restart \
            --cd /internal-config \
            --config $CONFIG_FILE_NAME
