FROM debian:bookworm-20230320-slim

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

COPY run.sh /run/
COPY disk.sh /run/
COPY power.sh /run/
COPY install.sh /run/
COPY network.sh /run/

RUN ["chmod", "+x", "/run/run.sh"]
RUN ["chmod", "+x", "/run/install.sh"]

VOLUME /storage

EXPOSE 22

ENV CPU_CORES 1
ENV DISK_SIZE 16G
ENV RAM_SIZE 512M

ENV BOOT http://www.tinycorelinux.net/13.x/x86/release/Core-13.1.iso

ENTRYPOINT ["/run/run.sh"]
