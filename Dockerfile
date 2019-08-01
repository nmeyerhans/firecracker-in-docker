# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
#
#      http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.
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
