FROM debian:trixie-slim

ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y upgrade && \
    apt-get --no-install-recommends -y install \
 	tini \
	wget \  
	procps \
	iptables \
	iproute2 \
	dnsmasq \
	net-tools \
	ca-certificates \
	netcat-openbsd \
	qemu-system-x86 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./src /run/
RUN chmod +x /run/*.sh

VOLUME /storage

EXPOSE 22
EXPOSE 5900

ENV CPU_CORES "1"
ENV DISK_SIZE "16G"
ENV RAM_SIZE "512M"
ENV BOOT "http://www.example.com/image.iso"

ARG VERSION_ARG="0.0"
ENV VERSION=$VERSION_ARG

LABEL org.opencontainers.image.title="QEMU for Docker"
LABEL org.opencontainers.image.description="QEMU in a docker container using KVM acceleration"

ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]
