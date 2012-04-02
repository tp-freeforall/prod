#!/bin/bash
#
# BUILD_ROOT is assumed to be the same directory as the build.sh file.
#
# mspgcc development branch: 4.6.2 (non-20 bit)
# binutils	2.21.1a
# gcc		4.6.2
# gdb		7.2a
# mspgcc	20120311
# msp430-libc	20120224
# msp430mcu	20120311
#
# gmp		4.3.2
# mpfr		3.0.0
# mpc		0.9
#
# set TOSROOT to the head of the tinyos source tree root.
#

BUILD_ROOT=$(pwd)

if [[ -z "${TOSROOT}" ]]; then
    TOSROOT=$(pwd)/../../../..
fi
echo -e "\n*** TOSROOT: $TOSROOT"

DEB_DEST=opt/msp430-462
REL=
MAKE_J=-j8

BINUTILS_VER=2.21.1
GCC_VER=4.6.2
GDB_VER=7.2

BINUTILS=binutils-${BINUTILS_VER}
GCC_CORE=gcc-core-${GCC_VER}
GCC=gcc-${GCC_VER}
GDB=gdb-${GDB_VER}

GMP_VER=4.3.2
MPFR_VER=3.0.0
MPC_VER=0.9

GMP=gmp-${GMP_VER}
MPFR=mpfr-${MPFR_VER}
MPC=mpc-${MPC_VER}

MSPGCC_VER=20120311
MSPGCC=mspgcc-${MSPGCC_VER}

PATCHES=""

if [[ "$1" == deb || "$1" == testdeb || "$1" == test ]]
then
    ARCH_TYPE=$(dpkg-architecture -qDEB_HOST_ARCH)
    PREFIX=$(pwd)/debian/${DEB_DEST}
    PACKAGES_DIR=${TOSROOT}/packages/${ARCH_TYPE}
    mkdir -p ${PACKAGES_DIR}
    mkdir -p ${PACKAGES_DIR/${ARCH_TYPE}/all}
fi

if [[ "$1" == rpm ]]
then
    PREFIX=$(pwd)/fedora/usr
fi

: ${PREFIX:=${TOSROOT}/local}

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
    echo -e "\n*** Downloading ... "
    echo "  ... ${BINUTILS}, ${GCC_CORE}, ${GDB}"
    [[ -a ${BINUTILS}a.tar.bz2 ]] \
	|| wget http://ftp.gnu.org/gnu/binutils/${BINUTILS}a.tar.bz2
    [[ -a ${GCC_CORE}.tar.bz2 ]] \
	|| wget http://ftp.gnu.org/gnu/gcc/${GCC}/${GCC_CORE}.tar.bz2
    [[ -a ${GDB}a.tar.bz2 ]] \
	|| wget http://ftp.gnu.org/gnu/gdb/${GDB}a.tar.bz2

    echo "  ... ${MPFR}, ${GMP}, ${MPC}"
    [[ -a ${MPFR}.tar.bz2 ]] \
	|| wget http://ftp.gnu.org/gnu/mpfr/${MPFR}.tar.bz2
    [[ -a ${GMP}.tar.bz2 ]] \
	|| wget http://ftp.gnu.org/gnu/gmp/${GMP}.tar.bz2
    [[ -a ${MPC}.tar.gz ]] \
	|| wget http://www.multiprecision.org/mpc/download/${MPC}.tar.gz

    echo "  ... ${MSPGCC} patches"
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

    # Download bugfix patches from the MSP430 LTS release
    echo "  ... LTS patches"
    [[ -z "${PATCHES}" ]] && echo "      none"
    for f in ${PATCHES}
    do
	# Note: the last_patch function relies on the wget setting the date right.
	[[ -a ${f} ]] \
	    || (echo "    ... ${f}"
	    wget -q http://sourceforge.net/projects/mspgcc/files/Patches/LTS/20110716/${f})
    done
    echo "*** Done"
}

patch_dirs()
{
    echo -e "\n*** Unpacking ${BINUTILS}a.tar.bz2"
    rm -rf ${BINUTILS}
    tar -xjf ${BINUTILS}a.tar.bz2
    set -e
    (
	cd ${BINUTILS}
	echo -e "\n***" mspgcc ${BINUTILS} patch
	cat ../${MSPGCC}/msp430-binutils-${BINUTILS_VER}a-*.patch | patch -p1
#	echo -e "\n***" LTS binutils bugfix patches...
#	cat ../msp430-binutils-*.patch | patch -p1
    )

    echo -e "\n***" Unpacking ${GCC_CORE}, ${MPFR}, ${GMP}, and ${MPC}
    rm -rf ${GCC} ${MPFR} ${GMP} ${MPC}
    echo ${GCC_CORE}.tar.bz2
    tar -xjf ${GCC_CORE}.tar.bz2
    echo ${MPFR}.tar.bz2
    tar -xjf ${MPFR}.tar.bz2
    echo ${GMP}.tar.bz2
    tar -xjf ${GMP}.tar.bz2
    echo ${MPC}.tar.gz
    tar -xzf ${MPC}.tar.gz
    set -e
    (
	cd ${GCC}
	ln -s ../${MPFR} mpfr
	ln -s ../${GMP}  gmp
	ln -s ../${MPC}  mpc

	echo -e "\n***" mspgcc ${GCC} patch
	cat ../${MSPGCC}/msp430-gcc-${GCC_VER}-*.patch | patch -p1
#	echo -e "\n*** LTS gcc bugfix patches..."
#	cat ../msp430-gcc-*.patch | patch -p1
    )

    echo -e "\n***" Unpacking ${GDB}
    rm -rf ${GDB}
    tar xjf ${GDB}a.tar.bz2
    set -e
    (
	cd ${GDB}
	echo -e "\n***" mspgcc ${GDB} patch
	cat ../${MSPGCC}/msp430-gdb-${GDB_VER}a-*.patch | patch -p1

# no extra patches.
#	echo -n "\n*** LTS gdb bugfix patches...
#	cat ../msp430-gdb-*.patch | patch -p1
    )

    echo -e "\n***" Unpacking ${MSP430MCU}
    rm -rf ${MSP430MCU}
    tar -xjf ${MSP430MCU}.tar.bz2

#    set -e
#    (
#	cd ${MSP430MCU}
#	echo -e "\n*** LTS msp430mcu bugfix patches..."
#	cat ../msp430mcu-*.patch | patch -p1
#    )

    echo -e "\n***" Unpacking ${MSP430LIBC}
    rm -rf ${MSP430LIBC}
    tar xjf ${MSP430LIBC}.tar.bz2
#    set -e
#    (
#	cd ${MSP430LIBC}
#	echo -e "\n*** LTS libc bugfix patches..."
#	cat ../msp430-libc-*.patch | patch -p1
#    )
}

build_binutils()
{
    set -e
    echo -e "\n***" building ${BINUTILS} "->" ${PREFIX}
    (
	cd ${BINUTILS}
	../${BINUTILS}/configure \
	    --prefix=${PREFIX} \
	    --target=msp430
	make ${MAKE_J}
	make install
#	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/info,/share/locale}
	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/locale}
	find ${PREFIX} -empty | xargs rm -rf
    )
#
# ${BUILD_ROOT}/msp430-binutils.files contains all files built so far.
# ie. all files built for binutils.
#
    ( cd $PREFIX ; find . -type f -o -type l) > ${BUILD_ROOT}/msp430-binutils.files
}

package_binutils_deb()
{
    set -e
    VER=${BINUTILS_VER}
    LAST_PATCH=$(last_patch msp430-binutils-*.patch)
    DEB_VER=${VER}-${REL}${MSPGCC_VER}${LAST_PATCH}
    PACKAGE_NAME=${PACKAGES_DIR}/msp430-binutils-exp-${DEB_VER}.deb
    echo -e "\n***" debian archive: ${PACKAGE_NAME}
    (
	cd ${BINUTILS}
	mkdir -p debian/DEBIAN debian/${DEB_DEST}
	cat ../msp430-binutils.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	rsync -a ../debian/${DEB_DEST}/ debian/${DEB_DEST}/
	dpkg-deb --build debian ${PACKAGE_NAME}
    )
}

package_binutils_rpm()
{
    VER=${BINUTILS_VER}
    LAST_PATCH=$(last_patch msp430-binutils-*.patch)
    RPM_VER=${VER}+${REL}${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-binutils.spec
}

build_gcc()
{
    echo -e "\n***" building ${GCC} "->" ${PREFIX}
    set -e
    (
	cd $GCC
	rm -rf build
	mkdir build
	cd build
	../configure \
	    --prefix=${PREFIX} \
	    --target=msp430 \
	    --enable-languages=c
#	CPPFLAGS=-D_FORTIFY_SOURCE=0 make ${MAKE_J}
	make ${MAKE_J}
	make install
#	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/info,/share/locale,/share/man/man7}
	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/locale}
	find ${PREFIX} -empty | xargs rm -rf
    )
#
# ${BUILD_ROOT}/msp430-gcc.files contains all files built so far.
# ie. all files built for binutils and gcc.  Its cummulative.
#
    ( cd $PREFIX ; find . -type f -o -type l) > ${BUILD_ROOT}/msp430-gcc.files
}

package_gcc_deb()
{
    set -e
    VER=${GCC_VER}
    LAST_PATCH=$(last_patch msp430-gcc-*.patch)
    DEB_VER=${VER}-${REL}${MSPGCC_VER}${LAST_PATCH}
    PACKAGE_NAME=${PACKAGES_DIR}/msp430-gcc-exp-${DEB_VER}.deb
    echo -e "\n***" debian archive: ${PACKAGE_NAME}
    (
	cd ${GCC}
	mkdir -p debian/DEBIAN debian/${DEB_DEST}
	cat ../msp430-gcc.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	rsync -a ../debian/${DEB_DEST}/ debian/${DEB_DEST}/
	(
	    cd debian/${DEB_DEST}
#
# remove all previously built files.   This leaves only those files we
# have explicilty built.
#
	    cat ${BUILD_ROOT}/msp430-binutils.files | xargs rm -rf
	    find . -empty | xargs rm -rf
	)
	dpkg-deb --build debian ${PACKAGE_NAME}
    )
}

package_gcc_rpm()
{
    VER=${GCC_VER}
    LAST_PATCH=$(last_patch msp430-gcc-*.patch)
    RPM_VER=${VER}+${REL}${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-gcc.spec
}

build_mcu()
{
    set -e
    (
	cd ${MSP430MCU}
	MSP430MCU_ROOT=$(pwd) scripts/install.sh ${PREFIX}
    )
#
# ${BUILD_ROOT}/msp430mcu.files contains all files built so far.
# ie. all files built for binutils and gcc.  Its cummulative.
#
    ( cd $PREFIX ; find . -type f -o -type l) > ${BUILD_ROOT}/msp430mcu.files
}

package_mcu_deb()
{
    set -e
    VER=${MSP430MCU_VER}
    LAST_PATCH="-$(last_patch msp430mcu-*.patch)"
    DEB_VER=${VER}
    PACKAGE_NAME=${PACKAGES_DIR}/msp430mcu-exp-${DEB_VER}.deb
    echo -e "\n***" debian archive: ${PACKAGE_NAME}
    (
	cd ${MSP430MCU}
	mkdir -p debian/DEBIAN debian/${DEB_DEST}
	rsync -a -m ../debian/${DEB_DEST}/ debian/${DEB_DEST}/
	(
	    cd debian/${DEB_DEST}
#
# remove all previously built files.   This leaves only those files we
# have explicilty built.
#
	    cat ${BUILD_ROOT}/msp430-gcc.files | xargs rm -rf
	    until find . -empty -exec rm -rf {} \; &> /dev/null
	    do : ; done
	)
	cat ../msp430mcu.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	dpkg-deb --build debian ${PACKAGE_NAME}
    )
}

package_mcu_rpm()
{
    VER=${MSP430MCU_VER}
    LAST_PATCH=$(last_patch msp430mcu-*.patch)
    RPM_VER=${VER}+${REL}${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430mcu.spec
}

build_libc()
{
    set -e
    (
	PATH=${PREFIX}/bin:${PATH}
	echo -e -n "\n*** which msp430-gcc: "
	which msp430-gcc
	msp430-gcc --version
	cd ${MSP430LIBC}
	cd src
	make PREFIX=${PREFIX} ${MAKE_J}
	make PREFIX=${PREFIX} install
    )
    ( cd $PREFIX ; find . -type f -o -type l) > ${BUILD_ROOT}/msp430-libc.files
}

package_libc_deb()
{
    set -e
    VER=${MSP430LIBC_VER}
    LAST_PATCH="-$(last_patch msp430-libc-*.patch)"
    DEB_VER=${VER}
    PACKAGE_NAME=${PACKAGES_DIR}/msp430-libc-exp-${DEB_VER}.deb
    echo -e "\n***" debian archive: ${PACKAGE_NAME}
    (
	cd ${MSP430LIBC}
	mkdir -p debian/DEBIAN debian/${DEB_DEST}
	rsync -a -m ../debian/${DEB_DEST}/ debian/${DEB_DEST}/
	(
	    cd debian/${DEB_DEST}
	    cat ${BUILD_ROOT}/msp430mcu.files | xargs rm -rf
	    until find . -empty -exec rm -rf {} \; &> /dev/null
	    do : ; done
	)
	cat ../msp430-libc.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	dpkg-deb --build debian ${PACKAGE_NAME}
    )
}

package_libc_rpm()
{
    VER=${MSP430LIBC_VER}
    LAST_PATCH=$(last_patch msp430-libc-*.patch)
    RPM_VER=${VER}+${REL}${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-libc.spec
}

build_gdb()
{
    set -e
    (
	cd ${GDB}
	../${GDB}/configure \
	    --prefix=${PREFIX} \
	    --target=msp430
	make ${MAKE_J}
	make install
#	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/info,/share/locale,/share/gdb/syscalls}
	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/locale,/share/gdb/syscalls}
	find ${PREFIX} -empty | xargs rm -rf
    )
}

package_gdb_deb()
{
    set -e
    VER=${GDB_VER}
    LAST_PATCH=$(last_patch msp430-gdb-*.patch)
    DEB_VER=${VER}-${REL}${MSPGCC_VER}${LAST_PATCH}
    PACKAGE_NAME=${PACKAGES_DIR}/msp430-gdb-exp-${DEB_VER}.deb
    echo -e "\n***" debian archive: ${PACKAGE_NAME}
    (
	cd ${GDB}
	mkdir -p debian/DEBIAN debian/${DEB_DEST}
	cat ../msp430-gdb.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	rsync -a ../debian/${DEB_DEST}/ debian/${DEB_DEST}/
	(
	    cd debian/${DEB_DEST}
	    cat ${BUILD_ROOT}/msp430-libc.files | xargs rm -rf
	    find . -empty | xargs rm -rf
	)
	dpkg-deb --build debian ${PACKAGE_NAME}
    )
}

package_gdb_rpm()
{
    VER=${GDB_VER}
    LAST_PATCH=$(last_patch msp430-gdb-*.patch)
    RPM_VER=${VER}+${REL}${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-gdb.spec
}

package_dummy_deb()
{
    set -e
    PACKAGE_NAME=${PACKAGES_DIR/${ARCH_TYPE}/all}/msp430-exp.deb
    echo -e "\n***" debian archive: ${PACKAGE_NAME}
    (
	mkdir -p tinyos
	cd tinyos
	mkdir -p debian/DEBIAN
	cat ../msp430-tinyos.control \
	    | sed 's/@version@/'$(date +%Y%m%d)'/' \
	    > debian/DEBIAN/control
	dpkg-deb --build debian ${PACKAGE_NAME}
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
    test)
	download
#	patch_dirs
#	build_binutils
#	package_binutils_deb
#	build_gcc
#	package_gcc_deb
#	build_mcu
#	package_mcu_deb
#	build_libc
#	package_libc_deb
	build_gdb
	package_gdb_deb
	package_dummy_deb
	;;

    testdeb)
	download
	package_binutils_deb
	package_gcc_deb
	package_mcu_deb
	package_libc_deb
	package_gdb_deb
	package_dummy_deb
	;;

    download)
	download
	patch_dirs
	;;

    clean)
	remove $(echo binutils-* gcc-* gdb-* mspgcc-* msp430-libc-2012* \
	    msp430mcu-* mpfr-* gmp-* mpc-* \
	    | fmt -1 | grep -v 'tar' | grep -v 'patch' | xargs)
	remove tinyos *.files debian fedora
	;;

    veryclean)
	remove binutils-* gcc-* gdb-* mspgcc-* msp430-libc-2012* \
	    msp430mcu-* mpfr-* gmp-* mpc-*
	remove tinyos *.patch *.files debian fedora
	;;

    deb)
	download
	patch_dirs
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
	patch_dirs
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
	patch_dirs
	build_binutils
	build_mcu
	build_gcc
	build_libc
	build_gdb
	;;
esac
