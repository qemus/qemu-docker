<h1 align="center">QEMU for Docker
<br />
<p align="center">
<img src="https://github.com/qemu-tools/qemu-docker/raw/master/.github/logo.png" title="Logo" style="max-width:100%;" width="256" />
</p>

<div align="center">

[![build_img]][build_url]
[![gh_last_release_svg]][qemu-docker-hub]
[![Docker Image Size]][qemu-docker-hub]

[build_url]: https://github.com/qemu-tools/qemu-docker/actions
[qemu-docker-hub]: https://github.com/orgs/qemu-tools/packages/container/package/qemu-docker

[build_img]: https://github.com/qemu-tools/qemu-docker/actions/workflows/build.yml/badge.svg
[Docker Image Size]: https://ghcr-badge.egpl.dev/qemu-tools/qemu-docker/size?color=SteelBlue
[gh_last_release_svg]: https://ghcr-badge.egpl.dev/qemu-tools/qemu-docker/tags?n=1&label=version&color=SteelBlue

</div></h1>
QEMU in a docker container using KVM acceleration.

## Features

 - KVM acceleration
 - Graceful shutdown

## Usage

Via `docker-compose.yml`

```yaml
version: "3"
services:
    qemu:
        container_name: qemu
        image: qemux/qemu-docker:latest
        environment:
            DISK_SIZE: "16G"
            BOOT: "http://www.example.com/image.iso"
        devices:
            - /dev/kvm
        cap_add:
            - NET_ADMIN                       
        ports:
            - 22:22
        restart: on-failure
        stop_grace_period: 1m        
```

Via `docker run`

```bash
docker run -it --rm -e "BOOT=http://www.example.com/image.iso" --device=/dev/kvm --cap-add NET_ADMIN qemux/qemu-docker:latest
```

## FAQ

  * ### How do I specify the boot disk?

    You can modify the `BOOT` environment variable to specify the URL of an ISO image:

    ```
    environment:
      BOOT: "http://www.example.com/image.iso"
    ```
    
    It will be downloaded only once, during the initial run of the container.

  * ### How do I change the size of the data disk?

    To expand the default size of 16 GB, locate the `DISK_SIZE` setting in your compose file and modify it to your preferred capacity:

    ```
    environment:
      DISK_SIZE: "16G"
    ```

  * ### How do I change the location of the data disk?

    To change the data disk's location from the default docker volume, include the following bind mount in your compose file and replace the path `/home/user/data` with the desired storage folder:

    ```
    volumes:
      - /home/user/data:/storage
    ```

  * ### How do I increase the amount of CPU/RAM?

    By default, a single core and 512MB of RAM is allocated to the container. To increase this, add the following environment variables:

    ```
    environment:
      CPU_CORES: "4"
      RAM_SIZE: "2048M"
    ```

  * ### How do I verify if my system supports KVM?

    To verify if your system supports KVM, run the following commands:

    ```
    sudo apt install cpu-checker
    sudo kvm-ok
    ```

    If you receive an error from `kvm-ok` indicating that KVM acceleration can't be used, check your BIOS settings.

  * ### How do I assign an individual IP address to the container?

    By default, the container uses bridge networking which shares the IP address with the host. 

    If you want to assign an individual IP address to the container, you can create a macvlan network as follows:

    ```
    $ docker network create -d macvlan \
        --subnet=192.168.0.0/24 \
        --gateway=192.168.0.1 \
        --ip-range=192.168.0.100/28 \
        -o parent=eth0 vlan
    ```
    
    Be sure to modify the values to match your local subnet. 

    Once you have created the network, modify the container's configuration in your compose file as follows:

    ```
    networks:
        vlan:             
            ipv4_address: 192.168.0.100
    ```
    
    Finally, add the network to the bottom of your compose file:

    ```
    networks:
        vlan:
            external: true
    ```
   
    An added benefit of this approach is that you won't have to perform any port mapping anymore, since all ports will be exposed by default.

    Please note that this IP address won't be accessible from the Docker host due to the design of macvlan, which doesn't permit communication between the two. If this is a concern, there are some workarounds available, but they go beyond the scope of this FAQ.

  * ### How can the container acquire an IP address via DHCP?

    After configuring the container for macvlan (see above), add the following lines to your compose file:

    ```
    environment:
        DHCP: "Y"
    devices:
        - /dev/vhost-net
    device_cgroup_rules:
        - 'c 510:* rwm'
    ```

    Please note that the exact `cgroup` rule number may vary depending on your system, but the log output will indicate the correct number in case of an error.
