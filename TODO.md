# The backlog... #

* Better image management. Currently we just build a single image that isn't suitable for use by multiple container simultaneously.

* vsock integration. Firecracker supports vsock for communication between host and VM. This can be useful for `docker exec` functionality. We could support this somehow. Currently the only way to interact with a VM is via the console or over the network, neither of which is optimal.

* IPv6 currently requires that we manually set up radvd on Docker's bridge interface. We could improve that, at the very least by automating the radvd setup.
