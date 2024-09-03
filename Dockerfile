FROM padhihomelab/alpine-base:3.20.1_0.19.0_0.2


ENV ENTRYPOINT_RUN_AS_ROOT=1

ENV CONFIG_FILE_NAME="client.conf"
ENV ENABLE_IPv6=0
ENV FORWARDED_PORTS=""


COPY start.sh    /usr/local/bin/start-vpn
COPY sockd.conf  /

COPY entrypoint-scripts \
     /etc/docker-entrypoint.d/99-extra-scripts


RUN chmod +x /usr/local/bin/start-vpn \
             /etc/docker-entrypoint.d/99-extra-scripts/*.sh \
 && apk add --no-cache --update \
            bash \
            bind-tools \
            dante-server \
            ip6tables \
            openvpn=2.6.11-r0


VOLUME [ "/config" ]

CMD start-vpn


HEALTHCHECK --interval=10s --timeout=5s --start-period=20s \
        CMD ping -c 3 google.com || exit 1
