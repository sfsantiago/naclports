#!/bin/bash
# Copyright (c) 2013 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

source pkg_info
source ../../build_tools/common.sh

export ac_cv_func_gethostbyname=yes
export ac_cv_func_getaddrinfo=no
export ac_cv_func_connect=yes
LDFLAGS+=" -Wl,--whole-archive -lnacl_io -Wl,--no-whole-archive -pthread -lstdc++"

if [ $NACL_GLIBC = 1 ]; then
  EXECUTABLE_DIR=.libs
else
  EXECUTABLE_DIR=.
fi

EXECUTABLES=src/${EXECUTABLE_DIR}/curl${NACL_EXEEXT}
CFLAGS+=" -DDEBUGBUILD"
#EXTRA_CONFIGURE_ARGS="--enable-debug --disable-curldebug"

BuildStep() {
  # Run the build twice, initially to build the sel_ldr version
  # and secondly to build the PPAPI version based on nacl_io.
  # Touch tool_main.c to ensure that it gets rebuilt each time.
  # This is the only file that depends on the PPAPI define and
  # therefore will differ between PPAPI and sel_ldr versions.
  local SRC_DIR=${NACL_PACKAGES_REPOSITORY}/${PACKAGE_DIR}
  if [ -f ${SRC_DIR}/src/tool_main.c ]; then
    touch ${SRC_DIR}/src/tool_main.c
  fi
  DefaultBuildStep

  Banner "Build curl_ppapi"
  touch ${SRC_DIR}/src/tool_main.c
  sed -i.bak "s/CFLAGS = /CFLAGS = -DPPAPI /" src/Makefile
  sed -i.bak "s/curl\$(EXEEXT)/curl_ppapi\$(EXEEXT)/" src/Makefile
  sed -i.bak "s/LIBS = \$(BLANK_AT_MAKETIME)/LIBS = -lppapi_simple -lnacl_io -lppapi_cpp -lppapi -lstdc++/" src/Makefile
  DefaultBuildStep
}

InstallStep() {
  DefaultInstallStep
  PUBLISH_DIR="${NACL_PACKAGES_PUBLISH}/curl"
  if [ "${NACL_ARCH}" = "pnacl" ]; then
    # Just set up the x86-64 version for now.
    local pexe="${EXECUTABLE_DIR}/curl${NACL_EXEEXT}"
    (cd src;
     TranslateAndWriteSelLdrScript ${pexe} x86-64 curl.x86-64.nexe curl
    )
    PUBLISH_DIR+=/pnacl
  else
    local nexe="${EXECUTABLE_DIR}/curl${NACL_EXEEXT}"
    WriteSelLdrScript src/curl ${nexe}
    PUBLISH_DIR+=/${NACL_LIBC}
  fi

  MakeDir ${PUBLISH_DIR}

  LogExecute mv src/${EXECUTABLE_DIR}/curl_ppapi${NACL_EXEEXT} \
                ${PUBLISH_DIR}/curl_ppapi_${NACL_ARCH}${NACL_EXEEXT}

  LogExecute python ${NACL_SDK_ROOT}/tools/create_nmf.py \
      ${NACL_CREATE_NMF_FLAGS} \
      ${PUBLISH_DIR}/curl_ppapi*${NACL_EXEEXT} \
      -s ${PUBLISH_DIR} \
      -o curl.nmf

  local CHROMEAPPS=${NACL_SRC}/libraries/hterm/src/chromeapps
  local LIB_DOT=${CHROMEAPPS}/libdot
  local NASSH=${CHROMEAPPS}/nassh
  LIBDOT_SEARCH_PATH=${CHROMEAPPS} ${LIB_DOT}/bin/concat.sh \
      -i ${NASSH}/concat/nassh_deps.concat \
      -o ${PUBLISH_DIR}/hterm.concat.js

  LogExecute cp ${START_DIR}/index.html ${PUBLISH_DIR}
  LogExecute cp ${START_DIR}/curl.js ${PUBLISH_DIR}
  LogExecute cp curl.nmf ${PUBLISH_DIR}
  LogExecute cp ${TOOLS_DIR}/naclterm.js ${PUBLISH_DIR}
  if [ ${NACL_ARCH} = pnacl ]; then
    sed -i.bak 's/x-nacl/x-pnacl/g' ${PUBLISH_DIR}/naclterm.js
  fi
}

PackageInstall
exit 0
