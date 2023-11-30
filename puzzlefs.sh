#!/bin/bash

mkdir -p /tmp/example-rootfs/algorithms
echo "Binary Search" > /tmp/example-rootfs/algorithms/binary-search.txt
echo "test" > /tmp/example-rootfs/algorithms/test.txt
echo "lorem ipsum" > /tmp/example-rootfs/lorem_ipsum.txt
tree /tmp/example-rootfs

cargo run --release -- build /tmp/example-rootfs /tmp/puzzlefs-image puzzlefs_example

mkdir /tmp/mounted-image

FIFO=$(mktemp -u)
mkfifo "$FIFO"
RUST_LOG=DEBUG cargo run --release -- mount -i "$FIFO" -f /tmp/puzzlefs-image puzzlefs_example /tmp/mounted-image &
STATUS=$(head -c1 "$FIFO")
if [ "$STATUS" = "s" ]; then
	echo "Mountpoint contains:"
	ls /tmp/mounted-image
else
	echo "Mounting puzzlefs on /tmp/mounted-image failed"
fi
