### Makefile --- build images and things...

IMAGE_SIZE?=1G
KERNEL?=/usr/local/bin/vmlinux

IMAGE=$(CURDIR)/image

FIRECTL_DIR=_submodules/firectl

$(FIRECTL_DIR)/Makefile:
	git submodule update --init $(FIRECTL_DIR)

firectl: $(FIRECTL_DIR)/Makefile
	$(MAKE) -C $(FIRECTL_DIR) build-in-docker
	cp $(FIRECTL_DIR)/firectl .

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

container: vmlinux firectl
	docker build -t fc .

run:
	docker run -v $(IMAGE):/root.img --device /dev/kvm:/dev/kvm:rw --device /dev/net/tun:/dev/net/tun:rw --cap-add=net_admin -e CPU_COUNT -e MEM_MB -e CPU_TEMPLATE -it --rm fc

clean:
	-rm -f image .image vmlinux firectl
	test ! -d $(FIRECTL_DIR) || $(MAKE) -C $(FIRECTL_DIR) clean

.PHONY: install run clean
