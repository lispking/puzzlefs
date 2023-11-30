#!/bin/bash

# 1. install
sudo apt install -y capnproto skopeo umoci tree jq

# 2. create example rootfs and test files
mkdir -p /tmp/example-rootfs/algorithms
echo "Binary Search" > /tmp/example-rootfs/algorithms/binary-search.txt
echo "test" > /tmp/example-rootfs/algorithms/test.txt
echo "lorem ipsum" > /tmp/example-rootfs/lorem_ipsum.txt
tree /tmp/example-rootfs

# 3. create puzzlefs image manifest digest
cargo run --release -- build /tmp/example-rootfs /tmp/puzzlefs-image puzzlefs_example

target/release/puzzlefs build -c /tmp/example-rootfs /tmp/puzzlefs-image puzzlefs_example

puzzlefs image manifest digest: 743b08e98105e637c47adb80a17ba21ed12eb31523a056a0970ff687551904d7

sudo mount -t puzzlefs -o oci_root_dir="/tmp/puzzlefs-image" -o image_manifest="04718eb872552abfdf44d563aa09bdf89343950a364d9ff555fc6e3657d383b4" none /mnt

# 4. create mounted image
mkdir /tmp/mounted-image

# 5. mount puzzlefs image to mounted image
cargo run --release -- mount /tmp/puzzlefs-image puzzlefs_example /tmp/mounted-image

target/release/puzzlefs mount /tmp/puzzlefs-image puzzlefs_example /tmp/mounted-image

# 6. check mounted image
mount|grep fuse

# 7. check mounted image content
journalctl --since "2 min ago" | grep puzzlefs
tree /tmp/mounted-image

# 8. puzzlefs image
cargo run --release -- enable-fs-verity /tmp/puzzlefs-image puzzlefs_example 9675f3a64bd612e634a6c97b29a23903962b7c3c5f3e48ee1543ce25eda69aac
cargo run --release -- mount --digest dc7129e1bde1daedaf42eb19210131ff9c1ae08a9e762337c9c749996ba714df /tmp/puzzlefs-image puzzlefs_example /tmp/mounted-image

target/release/puzzlefs enable-fs-verity /tmp/puzzlefs-image puzzlefs_example 743b08e98105e637c47adb80a17ba21ed12eb31523a056a0970ff687551904d7
target/release/puzzlefs mount --digest 743b08e98105e637c47adb80a17ba21ed12eb31523a056a0970ff687551904d7 /tmp/puzzlefs-image puzzlefs_example /tmp/mounted-image

# 9. create mounted image with verity enabled
tmp_file=$(mktemp -u)
touch $tmp_file
dd if=/dev/zero of=$tmp_file bs=1k count=1024
sudo losetup -f --show $tmp_file
sudo mkfs -t ext4 -F -b4096 -O verity /dev/loop1
sudo mount /dev/loop1 /mnt
sudo chown -R $(id -u):$(id -g) /mnt
sudo tune2fs -l /dev/loop1 | grep verity


capnp convert binary:json ~/puzzlefs/format/manifest.capnp Rootfs < /tmp/puzzlefs-image/blobs/sha256/9675f3a64bd612e634a6c97b29a23903962b7c3c5f3e48ee1543ce25eda69aac
capnp convert binary:json ~/puzzlefs/format/metadata.capnp InodeVector < /tmp/puzzlefs-image/blobs/sha256/9675f3a64bd612e634a6c97b29a23903962b7c3c5f3e48ee1543ce25eda69aac
