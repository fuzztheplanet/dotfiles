#!/usr/bin/env bash

sudo vmhgfs-fuse -o allow_other -o auto_unmount .host:/VM_shared /mnt/VM_shared/
vmware-user
