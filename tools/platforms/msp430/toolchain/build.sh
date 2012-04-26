#!/bin/bash

#
# mspgcc, msp430 gcc toolchain
# 4.5.3-LTS20110716
#

BINUTILS_VER=2.21.1
BINUTILS=binutils-${BINUTILS_VER}
GCC_VER=4.5.3
GCC_CORE=gcc-core-${GCC_VER}
GCC=gcc-${GCC_VER}
GDB_VER=7.2
GDB=gdb-${GDB_VER}

MSPGCC_VER=20110716
MSPGCC=mspgcc-${MSPGCC_VER}

PATCHES="
  msp430-binutils-2.21.1-20110716-sf3143071.patch
  msp430-binutils-2.21.1-20110716-sf3379341.patch
  msp430-binutils-2.21.1-20110716-sf3386145.patch
  msp430-binutils-2.21.1-20110716-sf3400711.patch
  msp430-binutils-2.21.1-20110716-sf3400750.patch
  msp430-gcc-4.5.3-20110706-sf3370978.patch
  msp430-gcc-4.5.3-20110706-sf3390964.patch
  msp430-gcc-4.5.3-20110706-sf3394176.patch
  msp430-gcc-4.5.3-20110706-sf3396639.patch
  msp430-gcc-4.5.3-20110706-sf3409864.patch
  msp430-gcc-4.5.3-20110706-sf3417263.patch
  msp430-gcc-4.5.3-20110706-sf3431602.patch
  msp430-gcc-4.5.3-20110706-sf3433730.patch
  msp430-gcc-4.5.3-20110706-sf3420924.patch
  msp430-gcc-4.5.3-20110706-sf3500740.patch
  msp430-libc-20110612-sf3387164.patch
  msp430-libc-20110612-sf3402836.patch
  msp430mcu-20110613-sf3379189.patch
  msp430mcu-20110613-sf3384550.patch
  msp430mcu-20110613-sf3400714.patch
"

MPFR_VER=2.4.2
MPFR=mpfr-${MPFR_VER}
GMP_VER=4.3.2
GMP=gmp-${GMP_VER}
MPC_VER=0.8.1
MPC=mpc-${MPC_VER}

if [[ "$1" == deb ]]
then
    ARCH_TYPE=$(dpkg-architecture -qDEB_HOST_ARCH)
    PREFIX=$(pwd)/debian/usr
    PACKAGES_DIR=$(pwd)/../../../../packages/${ARCH_TYPE}
    mkdir -p ${PACKAGES_DIR}
    mkdir -p ${PACKAGES_DIR/${ARCH_TYPE}/all}
fi

if [[ "$1" == rpm ]]
then
    PREFIX=$(pwd)/fedora/usr
fi

: ${PREFIX:=$(pwd)/../../../../local}

last_patch()
{
    # We need to use $@ because the file pattern is already expanded.
    if echo $@ | grep -v -q '*'
    then
	echo -n +
	ls -l -t --time-style=+%Y%m%d $@ | awk '{ print +$6}' | head -n1
    fi
}

download()
{
    [[ -a ${BINUTILS}a.tar.bz2 ]] \
	|| wget http://ftp.gnu.org/gnu/binutils/${BINUTILS}a.tar.bz2
    [[ -a ${GCC_CORE}.tar.gz ]] \
	|| wget http://ftp.gnu.org/gnu/gcc/${GCC}/${GCC_CORE}.tar.gz
    [[ -a ${GDB}a.tar.gz ]] \
	|| wget http://ftp.gnu.org/gnu/gdb/${GDB}a.tar.gz
    [[ -a ${GDB}a.tar.gz ]] \
	|| wget http://ftp.gnu.org/gnu/gdb/${GDB}a.tar.gz

    [[ -a ${MPFR}.tar.gz ]] \
	|| wget http://ftp.gnu.org/gnu/mpfr/${MPFR}.tar.gz
    [[ -a ${GMP}.tar.gz ]] \
	|| wget http://ftp.gnu.org/gnu/gmp/${GMP}.tar.gz
    [[ -a ${MPC}.tar.gz ]] \
	|| wget http://www.multiprecision.org/mpc/download/${MPC}.tar.gz

    [[ -a ${MSPGCC}.tar.bz2 ]] \
	|| wget http://sourceforge.net/projects/mspgcc/files/mspgcc/${MSPGCC}.tar.bz2
    # We need to unpack this in order to find what libc to download
    [[ -d ${MSPGCC} ]] \
	|| tar xjf ${MSPGCC}.tar.bz2
    MSP430MCU_VER=$(cat ${MSPGCC}/msp430mcu.version)
    MSP430MCU=msp430mcu-${MSP430MCU_VER}
    [[ -a ${MSP430MCU}.tar.bz2 ]] \
	|| wget http://sourceforge.net/projects/mspgcc/files/msp430mcu/${MSP430MCU}.tar.bz2
    MSP430LIBC_VER=$(cat ${MSPGCC}/msp430-libc.version)
    MSP430LIBC=msp430-libc-${MSP430LIBC_VER}
    [[ -a ${MSP430LIBC}.tar.bz2 ]] \
	|| wget http://sourceforge.net/projects/mspgcc/files/msp430-libc/${MSP430LIBC}.tar.bz2

    # Download some patches to the MSP430 LTS release
    for f in ${PATCHES}
    do
	# Note: the last_patch function relies on the wget setting the date right.
	[[ -a ${f} ]] \
	    || (echo Dowloading ${f}...
	    wget -q http://sourceforge.net/projects/mspgcc/files/Patches/LTS/20110716/${f})
    done
}

build_binutils()
{
    echo Unpacking ${BINUTILS}a.tar.bz2
    rm -rf ${BINUTILS}
    tar -xjf ${BINUTILS}a.tar.bz2
    set -e
    (
	cd ${BINUTILS}
	cat ../${MSPGCC}/msp430-binutils-${BINUTILS_VER}-*.patch | patch -p1
	echo Extra patches...
	cat ../msp430-binutils-*.patch | patch -p1
	../${BINUTILS}/configure \
	    --prefix=${PREFIX} \
	    --target=msp430
	make -j4
	make install
	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/info,/share/locale}
	find ${PREFIX} -empty | xargs rm -rf
    )
    ( cd $PREFIX ; find . -type f ) > msp430-binutils.files
}

package_binutils_deb()
{
    set -e
    (
	VER=${BINUTILS_VER}
	LAST_PATCH=$(last_patch msp430-binutils-*.patch)
	DEB_VER=${VER}-LTS${MSPGCC_VER}${LAST_PATCH}
	cd ${BINUTILS}
	mkdir -p debian/DEBIAN
	cat ../msp430-binutils.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	rsync -a ../debian/usr debian
	dpkg-deb --build debian \
	    ${PACKAGES_DIR}/msp430-binutils-${VER}.deb
    )
}

package_binutils_rpm()
{
    VER=${BINUTILS_VER}
    LAST_PATCH=$(last_patch msp430-binutils-*.patch)
    RPM_VER=${VER}+LTS${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-binutils.spec
}

build_gcc()
{
    echo Unpacking ${GCC_CORE}.tar.gz
    rm -rf ${GCC}
    tar -xzf ${GCC_CORE}.tar.gz

    echo Unpacking ${MPFR}.tar.gz
    rm -rf ${MPFR}
    tar -xzf ${MPFR}.tar.gz

    echo Unpacking ${GMP}.tar.gz
    rm -rf ${GMP}
    tar -xzf ${GMP}.tar.gz

    echo Unpacking ${MPC}.tar.gz
    rm -rf ${MPC}
    tar -xzf ${MPC}.tar.gz

    set -e
    (
	cd $GCC
	ln -s ../${MPFR} mpfr
	ln -s ../${GMP} gmp
	ln -s ../${MPC} mpc
	cat ../${MSPGCC}/msp430-gcc-${GCC_VER}-*.patch | patch -p1
	echo Extra patches...
	cat ../msp430-gcc-*.patch | patch -p1
	mkdir build
	cd build
	../configure \
	    --prefix=${PREFIX} \
	    --target=msp430 \
	    --enable-languages=c
	CPPFLAGS=-D_FORTIFY_SOURCE=0 make -j4
	make install
	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/info,/share/locale,/share/man/man7}
	find ${PREFIX} -empty | xargs rm -rf
    )
    ( cd $PREFIX ; find . -type f ) > msp430-gcc.files
}

package_gcc_deb()
{
    set -e
    (
	VER=${GCC_VER}
	LAST_PATCH=$(last_patch msp430-gcc-*.patch)
	DEB_VER=${VER}-LTS${MSPGCC_VER}${LAST_PATCH}
	cd ${GCC}
	mkdir -p debian/DEBIAN
	cat ../msp430-gcc.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	rsync -a ../debian/usr debian
	(
	    cd debian/usr
	    cat ../../../msp430-binutils.files | xargs rm -rf
	    find . -empty | xargs rm -rf
	)
	dpkg-deb --build debian \
	    ${PACKAGES_DIR}/msp430-gcc-${VER}.deb
    )
}

package_gcc_rpm()
{
    VER=${GCC_VER}
    LAST_PATCH=$(last_patch msp430-gcc-*.patch)
    RPM_VER=${VER}+LTS${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-gcc.spec
}

build_mcu()
{
    echo Unpacking ${MSP430MCU}.tar.bz2
    rm -rf ${MSP430MCU}
    tar xjf ${MSP430MCU}.tar.bz2
    set -e
    (
	cd ${MSP430MCU}
	echo Extra patches...
	cat ../msp430mcu-*.patch | patch -p1
	MSP430MCU_ROOT=$(pwd) scripts/install.sh ${PREFIX}
    )
    ( cd $PREFIX ; find . -type f ) > msp430mcu.files
}

package_mcu_deb()
{
    set -e
    (
	VER=${MSP430MCU_VER}
	LAST_PATCH=$(last_patch msp430mcu-*.patch)
	DEB_VER=${VER}-LTS${MSPGCC_VER}${LAST_PATCH}
	cd ${MSP430MCU}
	rsync -a -m ../debian/usr debian
	(
	    cd debian/usr
	    cat ../../../msp430-gcc.files | xargs rm -rf
	    until find . -empty -exec rm -rf {} \; &> /dev/null
	    do : ; done
	)
	mkdir -p debian/DEBIAN
	cat ../msp430mcu.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	dpkg-deb --build debian \
	    ${PACKAGES_DIR}/msp430mcu-${VER}.deb
    )
}

package_mcu_rpm()
{
    VER=${MSP430MCU_VER}
    LAST_PATCH=$(last_patch msp430mcu-*.patch)
    RPM_VER=${VER}+LTS${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430mcu.spec
}

build_libc()
{
    echo Unpacking ${MSP430LIBC}.tar.bz2
    rm -rf ${MSP430LIBC}
    tar xjf ${MSP430LIBC}.tar.bz2
    set -e
    (
	PATH=${PREFIX}/bin:${PATH}
	cd ${MSP430LIBC}
	echo Extra patches...
	cat ../msp430-libc-*.patch | patch -p1
	cd src
	make PREFIX=${PREFIX} -j4
	make PREFIX=${PREFIX} install
    )
    ( cd $PREFIX ; find . -type f ) > msp430-libc.files
}

package_libc_deb()
{
    set -e
    (
	VER=${MSP430LIBC_VER}
	LAST_PATCH=$(last_patch msp430-libc-*.patch)
	DEB_VER=${VER}-LTS${MSPGCC_VER}${LAST_PATCH}
	cd ${MSP430LIBC}
	rsync -a -m ../debian/usr debian
	(
	    cd debian/usr
	    cat ../../../msp430mcu.files | xargs rm -rf
	    until find . -empty -exec rm -rf {} \; &> /dev/null
	    do : ; done
	)
	mkdir -p debian/DEBIAN
	cat ../msp430-libc.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	dpkg-deb --build debian \
	    ${PACKAGES_DIR}/msp430-libc-${VER}.deb
    )
}

package_libc_rpm()
{
    VER=${MSP430LIBC_VER}
    LAST_PATCH=$(last_patch msp430-libc-*.patch)
    RPM_VER=${VER}+LTS${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-libc.spec
}

build_gdb()
{
    echo Unpacking ${GDB}a.tar.gz
    rm -rf ${GDB}
    tar xzf ${GDB}a.tar.gz
    set -e
    (
	cd ${GDB}
	cat ../${MSPGCC}/msp430-gdb-${GDB_VER}-*.patch | patch -p1
	echo Extra patches...
	cat ../msp430-gdb-*.patch | patch -p1
	../${GDB}/configure \
	    --prefix=${PREFIX} \
	    --target=msp430
	make -j4
	make install
	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/info,/share/locale,/share/gdb/syscalls}
	find ${PREFIX} -empty | xargs rm -rf
    )
}

package_gdb_deb()
{
    set -e
    (
	VER=${GDB_VER}
	LAST_PATCH=$(last_patch msp430-gdb-*.patch)
	DEB_VER=${VER}-LTS${MSPGCC_VER}${LAST_PATCH}
	cd ${GDB}
	mkdir -p debian/DEBIAN
	cat ../msp430-gdb.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	rsync -a ../debian/usr debian
	(
	    cd debian/usr
	    cat ../../../msp430-libc.files | xargs rm -rf
	    find . -empty | xargs rm -rf
	)
	dpkg-deb --build debian \
	    ${PACKAGES_DIR}/msp430-gdb-${VER}.deb
    )
}

package_gdb_rpm()
{
    VER=${GDB_VER}
    LAST_PATCH=$(last_patch msp430-gdb-*.patch)
    RPM_VER=${VER}+LTS${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-gdb.spec
}

package_dummy_deb()
{
    set -e
    (
	mkdir -p tinyos
	cd tinyos
	mkdir -p debian/DEBIAN
	cat ../msp430-tinyos.control \
	    | sed 's/@version@/'$(date +%Y%m%d)'/' \
	    > debian/DEBIAN/control
	dpkg-deb --build debian \
	    ${PACKAGES_DIR/${ARCH_TYPE}/all}/msp430-tinyos.deb
    )
}

remove()
{
    for f in $@
    do
	if [ -a ${f} ]
	then
	    echo Removing ${f}
	    rm -rf $f
	fi
    done
}

case $1 in
    download)
	download
	;;

    clean)
	remove $(echo binutils-* gcc-* gdb-* mspgcc-* msp430-libc-2011* \
	    msp430mcu-* mpfr-* gmp-* mpc-* \
	    | fmt -1 | grep -v 'tar' | grep -v 'patch' | xargs)
	remove tinyos *.files debian fedora
	;;

    veryclean)
	remove binutils-* gcc-* gdb-* mspgcc-* msp430-libc-2011* \
	    msp430mcu-* mpfr-* gmp-* mpc-*
	remove tinyos *.patch *.files debian fedora
	;;

    deb)
	download
	build_binutils
	package_binutils_deb
	build_gcc
	package_gcc_deb
	build_mcu
	package_mcu_deb
	build_libc
	package_libc_deb
	build_gdb
	package_gdb_deb
	package_dummy_deb
	;;

    rpm)
	download
	build_binutils
	package_binutils_rpm
	build_gcc
	package_gcc_rpm
	build_mcu
	package_mcu_rpm
	build_libc
	package_libc_rpm
	build_gdb
	package_gdb_rpm
	;;

    *)
	download
	build_binutils
	build_mcu
	build_gcc
	build_libc
	build_gdb
	;;
esac
