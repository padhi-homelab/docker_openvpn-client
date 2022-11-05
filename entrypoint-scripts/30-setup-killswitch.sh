#!/bin/sh

set -e

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

echo "Creating VPN kill switch and local routes..."

echo "Allowing established and related connections."
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
[ $ENABLE_IPv6 -eq 1 ] && ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "Allowing loopback connections."
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

[ $ENABLE_IPv6 -eq 1 ] && ip6tables -A INPUT -i lo -j ACCEPT
[ $ENABLE_IPv6 -eq 1 ] && ip6tables -A OUTPUT -o lo -j ACCEPT

echo "Allowing Docker network connections."
local_subnet_4=$(ip -4 r | grep -v 'default via' | grep eth0 | tail -n 1 | awk '{ print $1 }')
iptables -A INPUT -s $local_subnet_4 -j ACCEPT
iptables -A OUTPUT -d $local_subnet_4 -j ACCEPT

if [ $ENABLE_IPv6 -eq 1 ]; then
    local_subnet_6=$(ip -6 r | grep -v 'default via' | grep eth0 | tail -n 1 | awk '{ print $1 }')
    ip6tables -A INPUT -s $local_subnet_6 -j ACCEPT
    ip6tables -A OUTPUT -d $local_subnet_6 -j ACCEPT
fi

echo "Allowing remote servers in configuration file."
remote_port=$(grep "port " $CONFIG_FILE_NAME | awk '{ print $2 }')
remote_proto=$(grep "proto " $CONFIG_FILE_NAME | awk '{ print $2 }')
remote_proto="${remote_proto%-client}"
remotes=$(grep "remote " $CONFIG_FILE_NAME | awk '{ print $2,$3,$4 }')

echo "  Using:"
echo $remotes | while IFS= read line; do
    domain=$(echo "$line" | awk '{ print $1 }')
    port=$(echo "$line" | awk '{ print $2 }')
    [ "$port" = "${port#\#}" ] || port=""
    proto=$(echo "$line" | awk '{ print $3 }')
    [ "$proto" = "${proto#\#}" ] || proto=""

    if ip route get $domain > /dev/null 2>&1; then
        echo "    $domain PORT:${port:-$remote_port} ${proto:-$remote_proto}"
        iptables -A OUTPUT -o eth0 -d $domain -p ${proto:-$remote_proto} --dport ${port:-$remote_port} -j ACCEPT
    elif [ $ENABLE_IPv6 -eq 1 ] && ip -6 route get $domain > /dev/null 2>&1; then
        echo "    $domain PORT:${port:-$remote_port} ${proto:-$remote_proto}"
        ip6tables -A OUTPUT -o eth0 -d $domain -p ${proto:-$remote_proto} --dport ${port:-$remote_port} -j ACCEPT
    else
        grep -v "$line" $CONFIG_FILE_NAME > temp && mv temp $CONFIG_FILE_NAME

        IPv4s=$(dig -4 +short "$domain")
        if [ $? -eq 0 ]; then
            for ip in $IPv4s; do
                echo "    $domain (IP4:$ip PORT:${port:-$remote_port} ${proto:-$remote_proto})"
                iptables -A OUTPUT -o eth0 -d $ip -p ${proto:-$remote_proto} --dport ${port:-$remote_port} -j ACCEPT
                echo "remote $ip $port $proto" >> $CONFIG_FILE_NAME
            done
        fi

        if [ $ENABLE_IPv6 -eq 1 ]; then
            IPv6s=$(dig -6 +short "$domain")
            if [ $? -eq 0 ]; then
                for ip in $IPv6s; do
                    echo "    $domain (IP6:$ip PORT:${port:-$remote_port} ${proto:-$remote_proto})"
                    ip6tables -A OUTPUT -o eth0 -d $ip -p ${proto:-$remote_proto} --dport ${port:-$remote_port} -j ACCEPT
                    echo "remote $ip $port $proto" >> $CONFIG_FILE_NAME
                done
            fi
        fi
    fi
done

echo "Allowing connections over VPN interface."
iptables -A INPUT -i tun0 -j ACCEPT
iptables -A OUTPUT -o tun0 -j ACCEPT

[ $ENABLE_IPv6 -eq 1 ] && ip6tables -A INPUT -i tun0 -j ACCEPT
[ $ENABLE_IPv6 -eq 1 ] && ip6tables -A OUTPUT -o tun0 -j ACCEPT

echo "Opening up forwarded ports."
if [ ! -z $FORWARDED_PORTS ]; then
    for port in ${FORWARDED_PORTS//,/ }; do
        if $(echo $port | grep -Eq '^[0-9]+$') && [ $port -ge 1024 ] && [ $port -le 65535 ]; then
            iptables -A INPUT -i tun0 -p tcp --dport $port -j ACCEPT
            iptables -A INPUT -i tun0 -p udp --dport $port -j ACCEPT
            [ $ENABLE_IPv6 -eq 1 ] && ip6tables -A INPUT -i tun0 -p tcp --dport $port -j ACCEPT
            [ $ENABLE_IPv6 -eq 1 ] && ip6tables -A INPUT -i tun0 -p udp --dport $port -j ACCEPT
            echo "+ port $port"
        else
            echo "- WARNING: $port is not a valid port. Ignoring."
        fi
    done
fi

echo "Blocking everything else."
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

[ $ENABLE_IPv6 -eq 1 ] && ip6tables -P INPUT DROP
[ $ENABLE_IPv6 -eq 1 ] && ip6tables -P OUTPUT DROP
[ $ENABLE_IPv6 -eq 1 ] && ip6tables -P FORWARD DROP

echo "iptables rules created and routes configured!"
