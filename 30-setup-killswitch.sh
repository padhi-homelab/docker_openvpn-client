#!/bin/sh

# # # # 
#
# Mostly borrowed from:
# https://github.com/yacht7/docker-openvpn-client/blob/master/data/scripts/entry.sh
#
# Remote domain resolution was failing during openvpn connection,
# so I replace (in the config file) each remote domain name with remote IPs.
#
# # # #

cd /internal-config

local_subnet=$(ip r | grep -v 'default via' | grep eth0 | tail -n 1 | cut -d " " -f 1)

echo "Creating VPN kill switch and local routes..."

echo "Allowing established and related connections."
iptables -A INPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT

echo "Allowing loopback connections."
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

echo "Allowing Docker network connections."
iptables -A INPUT -s $local_subnet -j ACCEPT
iptables -A OUTPUT -d $local_subnet -j ACCEPT

echo "Allowing remote servers in configuration file."
remote_port=$(grep "port " $CONFIG_FILE_NAME | cut -d " " -f 2)
remote_proto=$(grep "proto " $CONFIG_FILE_NAME | cut -d " " -f 2 | cut -c1-3)
remotes=$(grep "remote " $CONFIG_FILE_NAME | cut -d " " -f 2-4)

echo "  Using:"
echo "$remotes" | while IFS= read line; do
    domain=$(echo "$line" | cut -d " " -f 1)
    port=$(echo "$line" | cut -d " " -f 2)
    [ "$port" = "${port#\#}" ] || port=""
    proto=$(echo "$line" | cut -d " " -f 3 | cut -c1-3)
    [ "$proto" = "${proto#\#}" ] || proto=""

    if ip route get $domain > /dev/null 2>&1; then
        echo "    $domain PORT:$port"
        iptables -A OUTPUT -o eth0 -d $domain -p ${proto:-$remote_proto} --dport ${port:-$remote_port} -j ACCEPT
    else
        grep -v "$line" $CONFIG_FILE_NAME > temp && mv temp $CONFIG_FILE_NAME
        for ip in $(dig -4 +short $domain); do
            echo "    $domain (IP:$ip PORT:$port)"
            iptables -A OUTPUT -o eth0 -d $ip -p ${proto:-$remote_proto} --dport ${port:-$remote_port} -j ACCEPT
            echo "remote $ip $port $proto" >> $CONFIG_FILE_NAME
        done
    fi
done

echo "Allowing connections over VPN interface."
iptables -A INPUT -i tun0 -j ACCEPT
iptables -A OUTPUT -o tun0 -j ACCEPT

echo "Allowing connections over VPN interface to forwarded ports."
if [ ! -z $FORWARDED_PORTS ]; then
    for port in ${FORWARDED_PORTS//,/ }; do
        if $(echo $port | grep -Eq '^[0-9]+$') && [ $port -ge 1024 ] && [ $port -le 65535 ]; then
            iptables -A INPUT -i tun0 -p tcp --dport $port -j ACCEPT
            iptables -A INPUT -i tun0 -p udp --dport $port -j ACCEPT
            echo "+ port $port"
        else
            echo "- WARNING: $port is not a valid port. Ignoring."
        fi
    done
fi

echo "Preventing everything else."
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

echo "iptables rules created and routes configured!"
