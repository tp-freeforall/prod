#!/bin/bash
#
# BUILD_ROOT is assumed to be the same directory as the build.sh file.
#
# Env variables used....
#
# TOSROOT	head of the tinyos source tree root.  Used for base of default repo
# PACKAGES_DIR	where packages get stashed.  Defaults to ${BUILD_ROOT}/packages
# REPO_DEST	Where the repository is being built (defaults to ${TOSROOT}/tools/repo)
# DEB_DEST	final home once installed.
# CODENAME	which part of the repository to place this build in.
#
# REPO_DEST	must contain a conf/distributions file for reprepro to work
#		properly.   One can be copied from $(TOSROOT)/tools/repo/conf.
#
# we use opt for these tools to avoid conflicting with placement from normal
# distribution paths (debian or ubuntu repositories).
#

BUILD_ROOT=$(pwd)

DEB_DEST=usr
CODENAME=squeeze

if [[ -z "${TOSROOT}" ]]; then
    TOSROOT=$(pwd)/..
fi

TINYOS_TOOLS_VER=1.2.4
TINYOS_TOOLS=tinyos-tools-${TINYOS_TOOLS_VER}
POST_VER=-tinyprod-2

setup_deb()
{
    ARCH_TYPE=$(dpkg-architecture -qDEB_HOST_ARCH)
    PREFIX=${BUILD_ROOT}/${TINYOS_TOOLS}/debian/${DEB_DEST}
    if [[ -z "${PACKAGES_DIR}" ]]; then
	PACKAGES_DIR=${BUILD_ROOT}/packages
    fi
    mkdir -p ${PACKAGES_DIR}
}


setup_rpm()
{
    PREFIX=$(BUILD_ROOT)/${TINYOS_TOOLS}/fedora/usr
}


setup_local()
{
    mkdir -p ${TOSROOT}/local
    ${PREFIX:=${TOSROOT}/local}
}

: ${PREFIX:=$(pwd)/../local}

LIBTOOLIZE=$(which libtoolize || which glibtoolize)

build()
{
    set -e
    echo -e "\n***" building ${TINYOS_TOOLS} "->" ${PREFIX}
    (
	aclocal
	${LIBTOOLIZE} --automake --force --copy
	automake --foreign --add-missing --copy
	autoconf
	./configure --prefix=${PREFIX}
	make
	make install
    )
}

package_deb()
{
    VER=${TINYOS_TOOLS_VER}
    DEB_VER=${VER}${POST_VER}
    echo -e "\n***" debian archive: ${TINYOS_TOOLS}
    cd ${TINYOS_TOOLS}
    find debian/usr/bin/ -type f \
	| xargs perl -i -pe 's#'${PREFIX}'#/usr#'
    mkdir -p debian/DEBIAN
    cat ../tinyos-tools.control \
	| sed 's/@version@/'${DEB_VER}'/' \
	| sed 's/@architecture@/'${ARCH_TYPE}'/' \
	> debian/DEBIAN/control
    dpkg-deb --build debian .
    mv *.deb ${PACKAGES_DIR}
}

package_rpm()
{
    echo Packaging ${TINYOS_TOOLS}
    find ${TINYOS_TOOLS}/fedora/usr/bin/ -type f \
	| xargs perl -i -pe 's#'${PREFIX}'#/usr#'
    rpmbuild \
	-D "version ${TINYOS_TOOLS_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb tinyos-tools.spec
}

case $1 in
    test)
	package_deb
	;;

    build)
	build
	;;

    clean)
	rm -rf ${TINYOS_TOOLS}
	echo For cleaning the tree run: git clean -d -f -x
	;;

    deb)
	setup_deb
	build
	package_deb
	;;

    repo)
	setup_deb
	if [[ -z "${REPO_DEST}" ]]; then
	    REPO_DEST=${TOSROOT}/tools/repo
	fi
	echo -e "\n*** Building Repository: [${CODENAME}] -> ${REPO_DEST}"
	echo -e   "*** Using packages from ${PACKAGES_DIR}\n"
	find ${PACKAGES_DIR} -iname "*.deb" -exec reprepro -b ${REPO_DEST} includedeb ${CODENAME} '{}' \;
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
	echo -e "    local | rpm | deb | repo | clean | download"
esac
