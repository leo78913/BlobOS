#!/bin/env bash

echo -e "===\nScript working directory: $(pwd)\n===\n"
if [ ! -d "build" ]; then
    echo "Build doesn't exist."
    exit 1
fi

	echo "Running the ISO via qemu-system-x86_64"
	qemu-system-x86_64 -cdrom build/BlobOS.iso\
        -serial stdio\
        -enable-kvm\
        -boot dc
