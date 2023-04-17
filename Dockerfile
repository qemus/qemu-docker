FROM debian:bookworm-20230411-slim

RUN apt-get update && apt-get -y upgrade && \
    apt-get --no-install-recommends -y install \
	wget \
	dnsmasq \
	iptables \
	iproute2 \
	bridge-utils \
	netcat-openbsd \
	ca-certificates \
	qemu-system-x86 \
    && apt-get clean

COPY run/*.sh /run/
RUN ["chmod", "+x", "/run/run.sh"]

VOLUME /storage

EXPOSE 22

ENV CPU_CORES 1
ENV DISK_SIZE 16G
ENV RAM_SIZE 512M

ARG BUILD_ARG=0
ARG VERSION_ARG="0.0"
ENV BUILD=$BUILD_ARG
ENV VERSION=$VERSION_ARG

ENV BOOT http://www.example.com/image.iso

ENTRYPOINT ["/run/run.sh"]
