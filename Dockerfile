FROM debian:stretch-slim

COPY vmlinux firecracker firectl /usr/local/bin/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get -y install \
	iproute2 \
	ipcalc && \
	apt-get clean && \
	rm -rf /usr/share/doc /var/cache/apt /var/lib/apt

COPY entrypoint.sh /entrypoint
ENTRYPOINT /entrypoint
