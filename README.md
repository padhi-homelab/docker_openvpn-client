# docker_openvpn-client <a href='https://github.com/padhi-homelab/docker_openvpn-client/actions?query=workflow%3A%22Docker+CI+Release%22'><img align='right' src='https://img.shields.io/github/workflow/status/padhi-homelab/docker_openvpn-client/Docker%20CI%20Release?logo=github&logoWidth=24&style=flat-square'></img></a>

<a href='https://microbadger.com/images/padhihomelab/openvpn-client'><img src='https://img.shields.io/microbadger/layers/padhihomelab/openvpn-client/latest?logo=docker&logoWidth=24&style=for-the-badge'></img></a>
<a href='https://hub.docker.com/r/padhihomelab/openvpn-client'><img src='https://img.shields.io/docker/image-size/padhihomelab/openvpn-client/latest?label=size%20%5Blatest%5D&logo=docker&logoWidth=24&style=for-the-badge'></img></a>

A multiarch [OpenVPN] Docker image, based on [Alpine Linux].

|        386         |       amd64        |       arm/v6       |       arm/v7       |       arm64        |      ppc64le       |       s390x        |
| :----------------: | :----------------: | :----------------: | :----------------: | :----------------: | :----------------: | :----------------: |
| :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |



## Usage

```
docker run --rm --detach \
           --name vpn_container
           --cap-add=NET_ADMIN \
           -e CONFIG_FILE_NAME=client.conf \
           -v /path/to/config:/config \
           -it padhihomelab/openvpn-client
```

Starts a container running an `openvpn` client with the provided client configuration.
<br>
To route traffic from other containers via this container, use `--net=container:vpn_container` with `docker run`.

_<More details to be added soon>_


[Alpine Linux]: https://alpinelinux.org/
[OpenVPN]:      https://github.com/OpenVPN/openvpn
