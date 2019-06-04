### Makefile --- build images and things...

IMAGE_SIZE?=1G

IMAGE=$(CURDIR)/image

$(IMAGE):
	truncate -s $(IMAGE_SIZE) $(IMAGE)

install: $(IMAGE)
	docker run --cap-add=sys_admin \
	--cap-add=sys_chroot \
	--security-opt=apparmor=unconfined \
	--rm \
	-v $(IMAGE):/img \
	debian:stretch sh -c " id && apt-get update && apt-get --no-install-recommends -y install debootstrap && debootstrap stretch /mnt && mkfs.ext4 -d /mnt /img"

run:
	docker run -v $(IMAGE):/root.img --device /dev/kvm:/dev/kvm:rw --device /dev/net/tun:/dev/net/tun:rw --cap-add=net_admin -e kernel=/usr/local/bin/vmlinux -it --rm fc

.PHONY: install run
