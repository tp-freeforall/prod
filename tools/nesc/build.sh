#!/bin/bash
#
# Duplicates what is in tools/platforms/msp430/toolchain*
#
# BUILD_ROOT is assumed to be the same directory as the build.sh file.
#
# set TOSROOT to the head of the tinyos source tree root.
# used to find PACKAGES_DIR.
#

BUILD_ROOT=$(pwd)

DEB_DEST=usr
MAKE_J=-j8

if [[ -z "${TOSROOT}" ]]; then
    TOSROOT=$(pwd)/../..
fi
echo -e "\n*** TOSROOT: $TOSROOT"
echo "*** Destination: ${DEB_DEST}"

NESC_VER=1.3.4
NESC=nesc-${NESC_VER}
POST_VER=

setup_deb()
{
    ARCH_TYPE=$(dpkg-architecture -qDEB_HOST_ARCH)
    PREFIX=${BUILD_ROOT}/${NESC}/debian/${DEB_DEST}
    PACKAGES_DIR=${TOSROOT}/packages
    PACKAGES_ARCH=${PACKAGES_DIR}/${ARCH_TYPE}
    mkdir -p ${PACKAGES_DIR} ${PACKAGES_DIR}/all ${PACKAGES_ARCH}
}


setup_rpm()
{
    PREFIX=${BUILD_ROOT}/${NESC}/fedora/${DEB_DEST}
}


setup_local()
{
    mkdir -p ${TOSROOT}/local
    ${PREFIX:=${TOSROOT}/local}
}


download()
{
    echo -e "\n*** Downloading ... "
    [[ -a ${NESC}.tar.gz ]] \
	|| wget http://downloads.sourceforge.net/project/nescc/nescc/v${NESC_VER}/${NESC}.tar.gz
}

build()
{
    echo Unpacking ${NESC}.tar.gz
    rm -rf ${NESC}
    tar -xzf ${NESC}.tar.gz
    set -e
    (
	cd ${NESC}
	./configure --prefix=${PREFIX}
	make
	make install-strip
    )
}

package_deb()
{
    VER=${NESC_VER}
    DEB_VER=${VER}${POST_VER}
    echo -e "\n***" debian archive: ${NESC}${POST_VER}
    cd ${NESC}
    mkdir -p debian/DEBIAN debian/${DEB_DEST}
    find debian/${DEB_DEST}/bin/ -type f \
	| xargs perl -i -pe 's#'${PREFIX}'#/'${DEB_DEST}'#'
    cat ../nesc.control \
	| sed 's/@version@/'${DEB_VER}'/' \
	| sed 's/@architecture@/'${ARCH_TYPE}'/' \
	> debian/DEBIAN/control
    dpkg-deb --build debian .
    mv *.deb ${PACKAGES_ARCH}
}


package_rpm()
{
    echo Packaging ${NESC}
    find fedora/usr/bin/ -type f \
	| xargs perl -i -pe 's#'${PREFIX}'#/usr#'
    rpmbuild \
	-D "version ${NESC_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb nesc.spec
}

remove()
{
    for f in $@
    do
	if [[ -a ${f} ]]
	then
	    echo Removing ${f}
	    rm -rf $f
	fi
    done
}

case $1 in
    test)
	setup_deb
	package_deb
	;;

    download)
        download
	;;

    build)
	build
	;;

    clean)
	remove ${NESC}
	;;

    veryclean)
	remove ${NESC}{,.tar.gz}
	;;

    deb)
	setup_deb
	download
	build
	package_deb
	;;

    rpm)
	setup_rpm
	download
	build
	package_rpm
	;;

    *)
	setup_local
	download
	build
	;;
esac
