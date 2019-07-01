# Firecracker in Docker #

This repository contains a small set of tools for constructing a
container image usable for executing
[firecracker](https://firecracker-microvm.io) MicroVM instances in
Docker containers. It is useful primarily as an experiment into
alternative mechanisms for the integration of firecracker into
container workflows, as distinct from the approaches taken by projects
such as
[firecracker-containerd](https://github.com/firecracker-microvm/firecracker-containerd)
and [kata containers](https://katacontainers.io).

The software sets up a container environment including the firecracker
VMM and firectl, and invokes an entrypoint that configures appropriate
integration between the container environment and the virtual machine.

IPv4 and IPv6 networking are supported.

Container storage, as it's typically thought of in Docker-like
environments, is not supported. The virtual machine's root disk image
is created and managed outside the container runtime's context.

See [HOWTO.md](./HOWTO.md) for instructions on getting started.
