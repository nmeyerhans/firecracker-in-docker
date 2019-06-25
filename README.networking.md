# How does networking work in this container? #

firecracker can only use tap devices.

Most container runtimes set up veth interfaces.

Using a technique called "tc-mirrorring", which I first saw in Kata
Containers (See https://github.com/kata-containers/runtime/pull/827),
we can redirect traffic between the container and the VM
interfaces. This is accomplished using tc's
[ingress/egress packet mirror/redir actions module](https://salsa.debian.org/debian/iproute2/blob/upstream/tc/m_mirred.c),
the kernel's "ingress" queing discipline, and some broad packet
matching magic.

Because the Firecracker VM contains its own network stack, it needs to
be configured with its own address and route configuration. For IPv4,
we extract the relevant details from the Docker-configured veth
interface and pass them to the kernel via the
[ip= parameter](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/filesystems/nfs/nfsroot.txt?h=v5.1#n82)

For IPv6, we configure a similar but slightly different selector to
match the packets we're interested in, but otherwise the redirection
is the same as IPv4.

IPv6 configuration in the VM is completely different from IPv4. We
can't pass v6 configuration info to the kernel along side the v4
configuration, so instead we rely on standard IPv6 stateless
autoconfiguration. To set this up, you'll need to do the following:

**Choose an IPv6 prefix** When working in a VPC, choose a random
[48-bit ULA prefix](https://en.wikipedia.org/wiki/Unique_local_address). Configure
route tables in your VPC to route some arbitrary /64 network from that
prefix to your instance's ENI, and **disable Source/Dest checking** on
the ENI.

**Configure Docker** to use IPv6 by passing `--ipv6=true
--fixed-cidr-v6=fdab:cdef:1234:5678::/64` to the dockerd command line
(substituting your instance's /64 for the one shown). You can ensure
that Docker is configured right in this case by running verifying that
`ip addr show dev docker0` indicates that you have an IP address from
your ULA range on the docker0 interface, and you can test bridge
connectivity with: `docker run -it debian:buster ping6 -w3 -c3 -n
fe80::1`.

**Configure radvd** Install text similar to the following in
`/etc/radvd.conf` and start radvd:

    interface docker0 {
            AdvSendAdvert on;
            prefix fdab:cdef:1234:5678::/64 {};
    };

With all of this configured, you should be able to launch a
containerized VM (`make run`) and send IPv4 and IPv6 traffic to and
from other instances in the VPC. IPv4 traffic can be routed to the
internet if you're behind a NAT gateway or have a public IPv4 address
assigned to the instance. IPv6 traffic is limited to staying within
the VPC due to limitations in the VPC IPv6 implementation...
