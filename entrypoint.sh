#!/bin/bash

set -e

veth_if=eth0
kernel=${kernel:-/vmlinux}
root_img=${root_img:-/root.img}
log_path=${firecracker_log:-/dev/null}

macaddr=$(ip link show ${veth_if} | perl -n -e 'm#link/ether\s+(\S+)# && print "$1"')
addrcidr=$(ip -oneline addr show dev ${veth_if} | awk '{print $4}')
addr=$(echo "$addrcidr" | cut -d/ -f1)
cidr=$(echo "$addrcidr" | cut -d/ -f2)
netmask=$(ipcalc --nocolor --nobinary "$addrcidr" | egrep '^Netmask:' | awk '{print $2}')
gw=$(ip --oneline ro | grep default | awk '{print $3}')

ip tuntap add mod tap name fctap0
ip link set fctap0 up addr "$macaddr"

tc qdisc add dev ${veth_if} ingress
tc qdisc add dev fctap0 ingress

echo "Setting up tc filters in netns"
tc filter add dev ${veth_if} \
   parent ffff: protocol all u32 \
   match u8 0 0 \
   action mirred egress redirect dev fctap0

tc filter add dev fctap0 \
   parent ffff: protocol all u32 \
   match u8 0 0 \
   action mirred egress redirect dev ${veth_if}

exec firectl --kernel "$kernel" \
	--root-drive "$root_img" \
	--disable-hyperthreading \
	--cpu-template=T2 \
	--ncpus=2 \
	--kernel-opts="rw console=ttyS0 noapic reboot=k panic=1 pci=off nomodules root=/dev/vda ip=${addr}::${gw}:${netmask}:::off::::" \
	--tap-device "fctap0/$macaddr" \
	--firecracker-log="$log_path"
