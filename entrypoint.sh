#!/bin/bash
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

set -e

kernel=${kernel:-/usr/local/bin/vmlinux}
root_img=${root_img:-/root.img}
log_path=${firecracker_log:-/dev/null}

cpu_cnt=${CPU_COUNT:-1}
mem_mb=${MEM_MB:-256}
cpu_template=${CPU_TEMPLATE:-T2}

veth_if=eth0
tap_if=tap0
macaddr=$(ip link show ${veth_if} | perl -n -e 'm#link/ether\s+(\S+)# && print "$1"')
addrcidr=$(ip -oneline -4 addr show dev ${veth_if} | awk '{print $4}')
addr=$(echo "$addrcidr" | cut -d/ -f1)
cidr=$(echo "$addrcidr" | cut -d/ -f2)
netmask=$(ipcalc --nocolor --nobinary "$addrcidr" | egrep '^Netmask:' | awk '{print $2}')
gw=$(ip --oneline -4 ro | grep default | awk '{print $3}')

ip tuntap add mod tap name ${tap_if}
ip link set ${tap_if} up addr "$macaddr"

tc qdisc add dev ${veth_if} ingress
tc qdisc add dev ${tap_if} ingress

echo "Setting up tc filters in netns"
set -x
tc filter add dev ${veth_if} \
   parent ffff: protocol all u32 \
   match u8 0 0 \
   action mirred egress redirect dev ${tap_if}

tc filter add dev ${veth_if} \
   parent ffff: protocol all u32 \
   match ip6 dst any \
   action mirred egress redirect dev ${tap_if}

tc filter add dev ${tap_if} \
   parent ffff: protocol all u32 \
   match u8 0 0 \
   action mirred egress redirect dev ${veth_if}

tc filter add dev ${tap_if} \
   parent ffff: protocol all u32 \
   match ip6 dst any \
   action mirred egress redirect dev ${veth_if}

add_drives=""
for f in /drives/*; do
    test -f "${f}" || continue
    add_drives+=" --add-drive=/${f}:rw "
done

exec capsh --drop=cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_linux_immutable,cap_net_bind_service,cap_net_broadcast,cap_net_admin,cap_net_raw,cap_ipc_lock,cap_ipc_owner,cap_sys_module,cap_sys_rawio,cap_sys_chroot,cap_sys_ptrace,cap_sys_pacct,cap_sys_admin,cap_sys_boot,cap_sys_nice,cap_sys_resource,cap_sys_time,cap_sys_tty_config,cap_mknod,cap_lease,cap_audit_write,cap_audit_control,cap_setfcap,cap_mac_override,cap_mac_admin,cap_syslog,cap_wake_alarm,cap_block_suspend,cap_audit_read -- -c "firectl --kernel \"$kernel\" \
     --root-drive \"$root_img\" \
	--disable-hyperthreading \
	--cpu-template=${cpu_template} \
	--ncpus=${cpu_cnt} \
	--memory=${mem_mb} \
	--kernel-opts=\"rw console=ttyS0 noapic reboot=k panic=1 pci=off nomodules root=/dev/vda ip=${addr}::${gw}:${netmask}:::off::::\" \
	--tap-device \"${tap_if}/$macaddr\" \
	--firecracker-log=\"$log_path\" \
	${add_drives}"
