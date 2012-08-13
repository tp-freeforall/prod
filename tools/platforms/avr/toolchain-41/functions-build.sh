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

#default variables: overridable in build.sh
DATE=`date +%Y%m%d`
PACKAGE_RELEASE=${DATE}

setup_generalvariables(){
	BUILD_ROOT=$(pwd)

	PREFIX=/usr
	CODENAME=squeeze
	MAKE_J=-j8

	if [[ -z "${TOSROOT}" ]]; then
		TOSROOT=$(pwd)/../..
	fi
	
	PACKAGES_DIR=${BUILD_ROOT}/packages
	INSTALLDIR=${BUILD_ROOT}/${PACKAGE_NAME}_${PACKAGE_VERSION}-${PACKAGE_RELEASE}/ #overrided in local mode
	
	echo -e "\n*** TOSROOT: $TOSROOT"
	echo      "*** Prefix: ${PREFIX}"
}

check_download()
{
	for filename in $@; do
		if ! [ -f $filename ]; then
			return 1
		fi
	done
	return 0
}

setup_local()
{
  mkdir -p ${TOSROOT}/local
  ${INSTALLDIR:=${TOSROOT}/local}
}

##parameters: 
#$1: directory
#$2: version
#$3: control file (default: debcontrol)
#$4: postinst file (default: debpostinst)
#$5: prerm file (default: debprerm)
package_deb_from()
{
	ARCH_TYPE=$(dpkg-architecture -qDEB_HOST_ARCH)
	install -d $1/DEBIAN
	#set up package control files
	if [ $3 ]; then 
		DEBCONTROL=$3
	else
		DEBCONTROL=${BUILD_ROOT}/debcontrol
	fi
	if [ $4 ]; then 
		DEBPOSTINST=$4
	else
		DEBPOSTINST=${BUILD_ROOT}/debpostinst
	fi
	if [ $5 ]; then 
		DEBPRERM=$5
	else
		DEBPRERM=${BUILD_ROOT}/debprerm
	fi
	#copy postinst/prerm script to its place
	if [ -f ${DEBPOSTINST} ]; then
		echo POSTINST ${DEBPOSTINST}
		cp ${DEBPOSTINST} ${1}/DEBIAN/postinst
		chmod 755 ${1}/DEBIAN/postinst
	fi
	if [ -f ${DEBPRERM} ]; then
		echo PRERM ${DEBPRERM}
		cp ${DEBPRERM} ${1}/DEBIAN/prerm
		chmod 755 ${1}/DEBIAN/prerm
	fi
	#set up version numbers, architecture
	sed "s/%{version}/${2}/g" ${DEBCONTROL}|\
		sed "s/%{architecture}/${ARCH_TYPE}/g">\
		${1}/DEBIAN/control
	#create pkg
	fakeroot dpkg-deb --build ${1}
	#create the pkg directoy
	install -d ${PACKAGES_DIR}
	for package in *.deb; do
		#add the architecture to the name
		newfilename=$(basename "$package")
		newfilename="${newfilename%.*}_${ARCH_TYPE}.deb"
		#move to the package directory
		mv ${package} ${PACKAGES_DIR}/${newfilename}
	done
}

##parameters: 
#$1: directory
#$2: version
#$3: release
#$4: prefix
#$5: spec file (default: rpm.spec)
package_rpm_from()
{
  if [ $5 ]; then 
		RPMSPEC=$5
	else
		RPMSPEC=${BUILD_ROOT}/rpm.spec
	fi
	rpmbuild  \
		-D "version ${2}" \
		-D "release ${3}" \
		-D "sourcedir ${1}/${4}" \
		-bb ${RPMSPEC}
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

