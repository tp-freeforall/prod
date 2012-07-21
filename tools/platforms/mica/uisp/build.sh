#!/bin/bash

# BUILD_ROOT is assumed to be the same directory as the build.sh file.
#
# set TOSROOT to the head of the tinyos source tree root.
# used to find default PACKAGES_DIR.
#
#
# Env variables used....
#
# TOSROOT	head of the tinyos source tree root.  Used for base of default repo
# PACKAGES_DIR	where packages get stashed.  Defaults to $(TOSROOT)/packages
# REPO_DEST	Where the repository is being built (no default)
# DEB_DEST	final home once installed.
# CODENAME	which part of the repository to place this build in.
#
# REPO_DEST	must contain a conf/distributions file for reprepro to work
#		properly.   One can be copied from $(TOSROOT)/tools/repo/conf.
#

BUILD_ROOT=$(pwd)

DEB_DEST=usr
CODENAME=squeeze

if [[ -z "${TOSROOT}" ]]; then
    TOSROOT=$(pwd)/../..
fi
echo -e "\n*** TOSROOT: $TOSROOT"
echo      "*** Destination: ${DEB_DEST}"

UISP_VER=20050519tinyos
UISP=uisp-${UISP_VER}

setup_deb()
{
    ARCH_TYPE=$(dpkg-architecture -qDEB_HOST_ARCH)
    PREFIX=${BUILD_ROOT}/${UISP}/debian/${DEB_DEST}
    if [[ -z "${PACKAGES_DIR}" ]]; then
	PACKAGES_DIR=${BUILD_ROOT}/packages
    fi
    mkdir -p ${PACKAGES_DIR}
}


setup_rpm()
{
    PREFIX=$(pwd)/${UISP}/fedora/${DEB_DEST}
}


setup_local()
{
    mkdir -p ${TOSROOT}/local
    ${PREFIX:=${TOSROOT}/local}
}


build()
{
    set -e
    (
	./bootstrap
	./configure --prefix=${PREFIX}
	make
	make install-strip
    )
}

package_deb()
{
    VER=${UISP_VER}
    DEB_VER=${VER}${POST_VER}
    echo -e "\n***" debian archive: ${DEB_VER}
    cd ${UISP}
    mkdir -p debian/DEBIAN debian/${DEB_DEST}
    find debian/${DEB_DEST}/bin/ -type f \
	| xargs perl -i -pe 's#'${PREFIX}'#/'${DEB_DEST}'#'
    cat ../uisp.control \
	| sed 's/@version@/'${DEB_VER}'/' \
	| sed 's/@architecture@/'${ARCH_TYPE}'/' \
	> debian/DEBIAN/control
    fakeroot dpkg-deb --build debian .
    mv *.deb ${PACKAGES_DIR}
}

package_rpm()
{
    echo Packaging ${UISP}
    find ${UISP}/fedora/usr/bin/ -type f \
	| xargs perl -i -pe 's#'${PREFIX}'#/usr#'
    rpmbuild \
	-D "version ${UISP_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb uisp-tinyos.spec

}

case $1 in
    build)
	build
	;;

    clean)
	git clean -d -f -x
	;;

    deb)
	setup_deb
	build
	package_deb
	;;

    rpm)
	setup_rpm
	build
	package_rpm
	;;

     local)
	setup_local
	build
	;;

    *)
	echo -e "\n./build.sh <target>"
	echo -e "    local | rpm | deb | clean | build"
esac
