### Makefile --- build images and things...

IMAGE_SIZE?=1G
KERNEL?=/usr/local/bin/vmlinux

IMAGE=$(CURDIR)/image

$(IMAGE):
	truncate -s $(IMAGE_SIZE) $(IMAGE)

.image: $(IMAGE)
	docker run --cap-add=sys_admin \
	--cap-add=sys_chroot \
	--security-opt=apparmor=unconfined \
	--rm \
	-v $(IMAGE):/img \
	debian:stretch sh -c " id && apt-get update && apt-get --no-install-recommends -y install debootstrap && debootstrap --include=tcpdump stretch /mnt && sed -i 's|root:\*:|root::|' /mnt/etc/shadow && mkfs.ext4 -d /mnt /img"
	touch .image

install: .image

container:
	cp $(KERNEL) vmlinux
	docker build -t fc .

run:
	docker run -v $(IMAGE):/root.img --device /dev/kvm:/dev/kvm:rw --device /dev/net/tun:/dev/net/tun:rw --cap-add=net_admin -e CPU_COUNT -e MEM_MB -e CPU_TEMPLATE -it --rm fc

clean:
	-rm -f image .image vmlinux

.PHONY: install run clean
