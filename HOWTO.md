# Firecracker in Docker #

## Prerequisites ##

You'll need a host capable of running Firecracker. See the [prerequisites section of the Firecracker Documentation](https://github.com/firecracker-microvm/firecracker/blob/master/docs/getting-started.md#prerequisites) for details.

You'll need to have Docker installed and configured. This tool **will not** work in Docker's "host mode" network configuration. Bridged networking (Docker's default) has been tested. In theory other network modes will work, but they are untested.

You'll need to have a Firecracker-compatible Linux kernel image. You can either build your own, or [download](https://s3.amazonaws.com/spec.ccfc.min/img/hello/kernel/hello-vmlinux.bin) the kernel image provided by the Firecracker project.

## Building ##

There are several useful `make` targets:

* install   - Construct a root filesystem for use with a microvm
* container - Construct a container image for use with Docker
* run       - Run a VM container with the images created by "install" and "container"

The `container` target will build the `firecracker` and `firectl` dependencies automatically. It will not build the vmlinux binary for you, so you must provide one. By default it will try to use `/usr/local/bin/vmlinux`. If you want to use a kernel image from a different location, provide it with the `KERNEL` make variable, e.g. `make container KERNEL=/tmp/my-kernel.bin`
The `install` target will build a VM root filesystem image based on Debian 10 (buster). The root account in the VM will have an empty password.

The `run` target will run a container based on the images created by the `container` and `install` targets above.

In theory, assuming you have a firecracker-compatible kernel image at ~/vmlinux, The following should take you from a completely uninitialized system to a VM login prompt:

`$ make container install run KERNEL=~/vmlinux`

## Running ##

As indicated above `make run` should get you minimally started. Behind the scenes that command will invoke the following:

`$ docker run -v $(IMAGE):/root.img --device /dev/kvm:/dev/kvm:rw --device /dev/net/tun:/dev/net/tun:rw --cap-add=net_admin -e CPU_COUNT -e MEM_MB -e CPU_TEMPLATE -it --rm fc`

This command sets up access to the root filesystem image, the KVM and tun devices, and the necessary permissions to glue Firecracker's network to Docker's network, then runs the containerized firecracker process. Environment variables specifying CPU count, memory size, and CPU type are passed through. Upon termination of the container, the container is removed by Docker. However, changes made to the VM root filesystem are persisted, so subsequent invocations of the same command will run with the same filesystem content.
