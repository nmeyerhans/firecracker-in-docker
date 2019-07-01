FROM debian:stretch-slim

ENV CPU_COUNT 1
ENV MEM_MB 256
ENV CPU_TEMPLATE T2

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get -y install \
	iproute2 \
	ipcalc && \
	apt-get clean && \
	rm -rf /usr/share/doc /var/cache/apt /var/lib/apt

COPY vmlinux firecracker firectl /usr/local/bin/
COPY entrypoint.sh /entrypoint
STOPSIGNAL SIGTERM
ENTRYPOINT [ "/entrypoint" ]
CMD []
