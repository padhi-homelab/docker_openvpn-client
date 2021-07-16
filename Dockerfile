FROM padhihomelab/alpine-base:3.14.0_0.19.0_0.2


ENV ENTRYPOINT_RUN_AS_ROOT=1

ENV CONFIG_FILE_NAME="client.conf"
ENV ENABLE_IPv6=0
ENV FORWARDED_PORTS=""


COPY 10-setup-volume.sh         /etc/docker-entrypoint.d/
COPY 20-setup-dev-tun.sh        /etc/docker-entrypoint.d/
COPY 30-setup-killswitch.sh     /etc/docker-entrypoint.d/
COPY 40-setup-proxy-auth.sh     /etc/docker-entrypoint.d/
COPY start.sh                   /usr/local/bin/start-vpn
COPY sockd.conf                 /


RUN chmod +x /etc/docker-entrypoint.d/* \
 && chmod +x /usr/local/bin/start-vpn \
 && apk add --no-cache --update \
            bind-tools \
            dante-server \
            ip6tables \
            openvpn=2.5.2-r0


VOLUME [ "/config" ]

CMD start-vpn


HEALTHCHECK --interval=10s --timeout=5s --start-period=20s \
        CMD ping -c 3 google.com || exit 1
