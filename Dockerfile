FROM debian:bookworm-20230411-slim

RUN apt-get update && apt-get -y upgrade && \
    apt-get --no-install-recommends -y install \
	wget \
	iptables \
	iproute2 \
	dnsmasq \
	net-tools \
	bridge-utils \
	ca-certificates \
	isc-dhcp-client \
	netcat-openbsd \
	qemu-system-x86 \
    && apt-get clean

COPY run/*.sh /run/
RUN ["chmod", "+x", "/run/run.sh"]

VOLUME /storage

EXPOSE 22

ENV ALLOCATE "Y"
ENV CPU_CORES "1"
ENV DISK_SIZE "16G"
ENV RAM_SIZE "512M"
ENV BOOT "http://www.example.com/image.iso"

ARG DATE_ARG=""
ARG BUILD_ARG=0
ARG VERSION_ARG="0.0"
ENV VERSION=$VERSION_ARG

LABEL org.opencontainers.image.created=${DATE_ARG}
LABEL org.opencontainers.image.revision=${BUILD_ARG}
LABEL org.opencontainers.image.version=${VERSION_ARG}
LABEL org.opencontainers.image.url=https://hub.docker.com/r/kroese/docker-qemu/
LABEL org.opencontainers.image.source=https://github.com/kroese/docker-qemu/

ENTRYPOINT ["/run/run.sh"]
