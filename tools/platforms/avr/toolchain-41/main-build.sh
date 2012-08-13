check_and_download(){
  check_download $DOWNLOADED_FILES
   if [ "$?" -eq "1" ]; then
     download
   fi
}

setup_generalvariables
cd ${BUILD_ROOT}
case $1 in
  test)
		installto
# 		cd ${BUILD_ROOT}
#		package_deb
    ;;

  download)
    check_and_download
    ;;

  build)
    build
    ;;

  remove)
		cleaninstall
		;;
	
  clean)
    cleanbuild
    cd ${BUILD_ROOT}
    cleaninstall
    ;;

  veryclean)
    cleanbuild
    cd ${BUILD_ROOT}
    cleandownloaded
    cd ${BUILD_ROOT}
    cleaninstall
    ;;

  deb)
    check_and_download
    cd ${BUILD_ROOT}
    unpack
    cd ${BUILD_ROOT}
    build
    cd ${BUILD_ROOT}
    installto
    cd ${BUILD_ROOT}
    package_deb
    ;;

  rpm)
    check_and_download
    cd ${BUILD_ROOT}
    unpack
    cd ${BUILD_ROOT}
    build
    cd ${BUILD_ROOT}
    installto
    cd ${BUILD_ROOT}
    package_rpm
    ;;

  repo)
    setup_deb
    cd ${BUILD_ROOT}
    if [[ -z "${REPO_DEST}" ]]; then
      REPO_DEST=${TOSROOT}/tools/repo
    fi
    echo -e "\n*** Building Repository: [${CODENAME}] -> ${REPO_DEST}"
    echo -e   "*** Using packages from ${PACKAGES_DIR}\n"
    find ${PACKAGES_DIR} -iname "*.deb" -exec reprepro -b ${REPO_DEST} includedeb ${CODENAME} '{}' \;
    ;;

  local)
    setup_local
    cd ${BUILD_ROOT}
    check_and_download
    cd ${BUILD_ROOT}
    unpack
    cd ${BUILD_ROOT}
    build
    cd ${BUILD_ROOT}
    installto
    ;;

  *)
    echo -e "\n./build.sh <target>"
    echo -e "    local | rpm | deb | repo | clean | veryclean | download"
esac
