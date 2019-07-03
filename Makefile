### Makefile --- build images and things...
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

IMAGE_SIZE?=1G
KERNEL?=/usr/local/bin/vmlinux

IMAGE=$(CURDIR)/image

FIRECTL_DIR=_submodules/firectl
FIRECRACKER_DIR=_submodules/firecracker
CARGO_SYSTEM=$(shell uname -m)-unknown-linux-musl
CARGO_CACHE=.cargo_cache
FIRECRACKER_CARGO=docker run --rm -v $(CURDIR)/$(FIRECRACKER_DIR):/src \
	-v $(CURDIR)/$(CARGO_CACHE):/usr/local/cargo/registry \
	--workdir /src --user=$(shell id -u) \
	localhost/firecracker-build:latest cargo

$(FIRECTL_DIR)/Makefile:
	git submodule update --init $(FIRECTL_DIR)

firectl: $(FIRECTL_DIR)/Makefile
	$(MAKE) -C $(FIRECTL_DIR) build-in-docker
	cp $(FIRECTL_DIR)/firectl .

$(FIRECRACKER_DIR)/Cargo.toml:
	git submodule update --init $(FIRECRACKER_DIR)

firecracker: $(FIRECRACKER_DIR)/Cargo.toml
	mkdir -p $(CARGO_CACHE)
	cd tools && docker build -t localhost/firecracker-build:latest -f Dockerfile.firecracker .
	$(FIRECRACKER_CARGO) build --release
	cp $(FIRECRACKER_DIR)/target/$(CARGO_SYSTEM)/release/firecracker .

$(IMAGE):
	truncate -s $(IMAGE_SIZE) $(IMAGE)

.image: $(IMAGE)
	docker run --cap-add=sys_admin \
	--cap-add=sys_chroot \
	--security-opt=apparmor=unconfined \
	--rm \
	-v $(IMAGE):/img \
	debian:buster sh -c " id && apt-get update && apt-get --no-install-recommends -y install debootstrap && debootstrap --include=tcpdump buster /mnt && sed -i 's|root:\*:|root::|' /mnt/etc/shadow && mkfs.ext4 -d /mnt /img"
	touch .image

install: .image

vmlinux:
	cp $(KERNEL) vmlinux

container: vmlinux firectl firecracker
	docker build -t fc .

run:
	docker run -v $(IMAGE):/root.img \
		--device /dev/kvm:/dev/kvm:rw \
		--device /dev/net/tun:/dev/net/tun:rw \
		--cap-add=net_admin \
		-e CPU_COUNT \
		-e MEM_MB \
		-e CPU_TEMPLATE \
		$(EXTRA) \
		-it --rm fc

clean:
	-rm -f image .image vmlinux firectl firecracker
	-test ! -d $(FIRECTL_DIR) || $(MAKE) -C $(FIRECTL_DIR) clean
	-test ! -d $(FIRECRACKER_DIR) || $(FIRECRACKER_CARGO) clean

distclean: clean
	rm -rf $(CARGO_CACHE)
	-docker rmi localhost/firecracker-build:latest

help:
	@echo Useful makefile targets:
	@echo
	@echo 'install   - Construct a root filesystem for use with a microvm'
	@echo 'container - Construct a container image for use with Docker'
	@echo 'run       - Run a VM container with the images created by "install" and "container"'

.PHONY: install run clean container distclean help
