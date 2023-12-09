<h1 align="center">QEMU for Docker<br />
<div align="center">
<img src="https://github.com/qemu-tools/qemu-docker/raw/master/.github/logo.png" title="Logo" style="max-width:100%;" width="128" />
</div>
<div align="center">

[![Build]][build_url]
[![Version]][tag_url]
[![Size]][tag_url]
[![Pulls]][hub_url]

</div></h1>

QEMU in a docker container for running AMD64 virtual machines (even on ARM64).

It uses high-performance QEMU options (KVM acceleration, kernel-mode networking, etc) to achieve near-native speed.

## Features

 - Multi-platform
 - KVM acceleration

## Usage

Via `docker-compose.yml`

```yaml
version: "3"
services:
  qemu:
    container_name: qemu
    image: qemux/qemu-docker:latest
    environment:
      DISPLAY: "vnc"
      DISK_SIZE: "16G"
      BOOT: "https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/alpine-standard-3.18.2-x86_64.iso"
    devices:
      - /dev/kvm
    cap_add:
      - NET_ADMIN
    ports:
      - 2222:22
      - 5900:5900
    restart: on-failure
```

Via `docker run`

```bash
docker run -it --rm -e "BOOT=http://www.example.com/image.iso" --device=/dev/kvm --cap-add NET_ADMIN qemux/qemu-docker:latest
```

## FAQ

  * ### How do I specify the boot disk?

    You can modify the `BOOT` environment variable to specify the URL of an ISO image:

    ```yaml
    environment:
      BOOT: "https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/alpine-standard-3.18.2-x86_64.iso"
    ```
    
    It will be downloaded only once, during the initial run of the container.

  * ### How do I change the size of the data disk?

    To expand the default size of 16 GB, locate the `DISK_SIZE` setting in your compose file and modify it to your preferred capacity:

    ```yaml
    environment:
      DISK_SIZE: "128G"
    ```
    
    This can also be used to resize the existing disk to a larger capacity without any data loss.
    
  * ### How do I change the location of the data disk?

    To change the data disk's location from the default Docker volume, include the following bind mount in your compose file:

    ```yaml
    volumes:
      - /home/user/data:/storage
    ```

    Replace the example path `/home/user/data` with the desired storage folder.

  * ### How do I increase the amount of CPU or RAM?

    By default, a single core and 1 GB of RAM are allocated to the container. To increase this, add the following environment variables:

    ```yaml
    environment:
      RAM_SIZE: "4G"
      CPU_CORES: "4"
    ```

  * ### How do I verify if my system supports KVM?

    To verify if your system supports KVM, run the following commands:

    ```bash
    sudo apt install cpu-checker
    sudo kvm-ok
    ```

    If you receive an error from `kvm-ok` indicating that KVM acceleration can't be used, check your BIOS settings.

  * ### How can I connect with VNC?

    To enable VNC, add the following lines to your compose file:

    ```yaml
    environment:
      DISPLAY: "vnc"
    ports:
      - 5900:5900
    ```

    Afterwards you can connect with any VNC client to port 5900.

  * ### How do I provide custom arguments to QEMU?

    You can create the `ARGUMENTS` environment variable to provide additional arguments to QEMU at runtime:

    ```yaml
    environment:
      ARGUMENTS: "-usbdevice tablet"
    ```

  * ### How can I use qcow2 disk files?

    Add the following lines to your compose file

    ```yaml
    environment:
      DISK_FMT: "qcow2"
    ```

  * ### How do I assign an individual IP address to the container?

    By default, the container uses bridge networking, which shares the IP address with the host. 

    If you want to assign an individual IP address to the container, you can create a macvlan network as follows:

    ```bash
    docker network create -d macvlan \
        --subnet=192.168.0.0/24 \
        --gateway=192.168.0.1 \
        --ip-range=192.168.0.100/28 \
        -o parent=eth0 vlan
    ```
    
    Be sure to modify these values to match your local subnet. 

    Once you have created the network, change your compose file to look as follows:

    ```yaml
    services:
      qemu:
        container_name: qemu
        ..<snip>..
        networks:
          vlan:
            ipv4_address: 192.168.0.100

    networks:
      vlan:
        external: true
    ```
   
    An added benefit of this approach is that you won't have to perform any port mapping anymore since all ports will be exposed by default.

    Please note that this IP address won't be accessible from the Docker host due to the design of macvlan, which doesn't permit communication between the two. If this is a concern, you need to create a [second macvlan](https://blog.oddbit.com/post/2018-03-12-using-docker-macvlan-networks/#host-access) as a workaround.

  * ### How can the container acquire an IP address from my router?

    After configuring the container for macvlan (see above), it is possible for the VM to become part of your home network by requesting an IP from your router, just like your other devices.

    To enable this feature, add the following lines to your compose file:

    ```yaml
    environment:
      DHCP: "Y"
    devices:
      - /dev/vhost-net
    device_cgroup_rules:
      - 'c *:* rwm'
    ```

    Please note that even if you don't need DHCP, it's still recommended to enable this feature as it prevents NAT issues and increases performance by using a `macvtap` interface.

[build_url]: https://github.com/qemu-tools/qemu-docker/
[hub_url]: https://hub.docker.com/r/qemux/qemu-docker/
[tag_url]: https://hub.docker.com/r/qemux/qemu-docker/tags

[Build]: https://github.com/qemu-tools/qemu-docker/actions/workflows/build.yml/badge.svg
[Size]: https://img.shields.io/docker/image-size/qemux/qemu-docker/latest?color=066da5&label=size
[Pulls]: https://img.shields.io/docker/pulls/qemux/qemu-docker.svg?style=flat&label=pulls&logo=docker
[Version]: https://img.shields.io/docker/v/qemux/qemu-docker/latest?arch=amd64&sort=semver&color=066da5
