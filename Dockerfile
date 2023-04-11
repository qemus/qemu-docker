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
EXPOSE 80
EXPOSE 443 

ENV CPU_CORES 1
ENV DISK_SIZE 16G
ENV RAM_SIZE 512M

ENV BOOT https://ftp.halifax.rwth-aachen.de/osdn/clonezilla/78259/clonezilla-live-3.0.3-22-amd64.iso

ENTRYPOINT ["/run/run.sh"]
