#!/bin/bash
#
# Duplicates what is in tools/platforms/msp430/toolchain*
#
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

COMMON_FUNCTIONS_SCRIPT=../functions-build.sh
MAIN_SCRIPT=../main-build.sh
source ${COMMON_FUNCTIONS_SCRIPT}


SOURCENAME=binutils
SOURCEVERSION=2.17
SOURCEDIRNAME=${SOURCENAME}-${SOURCEVERSION}
SOURCEFILENAME=${SOURCEDIRNAME}.tar.bz2
PACKAGE_NAME=avr-${SOURCENAME}-tinyos
PACKAGE_VERSION=${SOURCEVERSION}
#PACKAGE_RELEASE=1
DOWNLOADED_FILES="30-binutils-2.17-avr-size.patch 31-binutils-2.17-avr-coff.patch 50-binutils-2.17-atmega256x.patch 51-binutils-2.17-newdevices.patch ${SOURCEFILENAME}"

download()
{
  wget http://ftp.gnu.org/gnu/${SOURCENAME}/${SOURCEFILENAME}
  svn co https://winavr.svn.sourceforge.net/svnroot/winavr/trunk/patches/binutils/2.17/ .
  rm -rf .svn
}

unpack()
{
  tar -xjf ${SOURCEFILENAME}
  cp *.patch ${SOURCEDIRNAME}
  cd ${SOURCEDIRNAME}
  cat *.patch|patch -p0
}

build()
{
  set -e
  (
    cd ${SOURCEDIRNAME}
    ./configure --prefix=${PREFIX} --disable-nls --infodir=${PREFIX}/share/info --libdir=${PREFIX}/lib --mandir=${PREFIX}/share/man --disable-werror --target=avr
    make ${MAKE_J}
  )
}

installto()
{
	cd ${SOURCEDIRNAME}
  make tooldir=/usr DESTDIR=${INSTALLDIR} install
  #cleanup
  rm -f ${INSTALLDIR}/usr/lib/libiberty.a
  rm -f ${INSTALLDIR}/usr/share/info/dir
  #remove everything without avr
  for filename in `ls ${INSTALLDIR}/usr/bin/|grep -v avr`; do
		rm -f ${INSTALLDIR}/usr/bin/$filename
	done
	#rename info files to avr-*
	for filename in `ls ${INSTALLDIR}/usr/share/info`; do
		mv ${INSTALLDIR}/usr/share/info/$filename ${INSTALLDIR}/usr/share/info/avr-$filename
	done
}

package_deb(){
  package_deb_from ${INSTALLDIR} ${PACKAGE_VERSION}-${PACKAGE_RELEASE} binutils.control
}

package_rpm(){
  package_rpm_from ${INSTALLDIR} ${PACKAGE_VERSION} ${PACKAGE_RELEASE} ${PREFIX} binutils.spec
}

cleanbuild(){
  remove ${SOURCEDIRNAME}
}

cleandownloaded(){
  remove ${DOWNLOADED_FILES}
}

cleaninstall(){
  remove ${INSTALLDIR}
}

source ${MAIN_SCRIPT}
