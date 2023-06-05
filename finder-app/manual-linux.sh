#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
ORIGINAL_DIR=`pwd`



if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- mrproper
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig
    make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- all
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- modules
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- dtbs     
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image {$OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
mkdir -p rootfs
if [ -d "${OUTDIR}/rootfs" ]
	# TODO: Create necessary base directories
	cd ${OUTDIR}/rootfs
	mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
	mkdir -p usr/bin usr/lib usr/sbin
	mkdir -p var/log
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
    mkdir -p ${OUTDIR}/rootfs
    cd ${OUTDIR}/rootfs
	mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
	mkdir -p usr/bin usr/lib usr/sbin
	mkdir -p var/log
fi

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
else
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
fi

# TODO: Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install    

cd ${OUTDIR}/rootfs
echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs (10:39 of video "Linux Root Filesystems")
cp ${ORIGINAL_DIR}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/
cp ${ORIGINAL_DIR}/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/
cp ${ORIGINAL_DIR}/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/
cp ${ORIGINAL_DIR}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/

# TODO: Make device nodes
cd ${OUTDIR}/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 622 dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${ORIGINAL_DIR}
make clean
make CROSS_COMPILE=aarch64-none-linux-gnu-
cd ${OUTDIR}/rootfs
cp ${ORIGINAL_DIR}/writer ./home

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
#  finder.sh, conf/username.txt and (modified as described in step 1 above) finder-test.sh
cd ${OUTDIR}/rootfs
cp ${ORIGINAL_DIR}/finder.sh ./home
cp ${ORIGINAL_DIR}/conf/username.txt ./home
cp ${ORIGINAL_DIR}/finder-test.sh ./home
cp ${ORIGINAL_DIR}/autorun-qemu.sh ./home

# TODO: Chown the root directory
sudo chown -R root:root .

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
cd ${OUTDIR}
gzip -f initramfs.cpio
echo $ORIGINAL_DIR


