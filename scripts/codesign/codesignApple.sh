#!/bin/bash -ex

#
# REMEMBER TO ALWAYS PRESERVE SYMLINKS WHEN ZIP and UNZIP
#
# Verification steps after codesign
# 1. spctl -avvvv pkg_name.app
#    Results "accepted" and Couchbase ID must be present 
# 2. codesign -dvvvv pkg_name.app
#    Sealed resource must be version 2
# 3. Best to upload to another website (latestbuilds), download from there and rerun step #1 and #2
#
#

function usage
    {
    echo "Incorrect parameters..."
    echo -e "\nUsage:  ${0}   version   builld_num   edition    OSX (eg. elcaptian) [1 = download package]\n\n"
    }

if [[ "$#" < 2 ]] ; then usage ; exit DEAD ; fi

# enable nocasematch
shopt -s nocasematch

PKG_VERSION=${1}  # Product Version

PKG_BUILD_NUM=${2}  # Build Number

EDITION=${3} # enterprise vs community

OSX=${4} # macos vs elcapitan 

DOWNLOAD_NEW_PKG=${5}  # Get new build 


if [[ ${PKG_VERSION} =~ "4.0.0" ]] || [[ ${PKG_VERSION} =~ "4.1.0" ]]
then
    PKG_URL=http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/${PKG_BUILD_NUM}
    PKG_NAME=couchbase-server-${EDITION}_${PKG_VERSION}-${PKG_BUILD_NUM}-${OSX}_x86_64.zip
    PKG_DIR=couchbase-server-${EDITION}_4
else
    PKG_URL=http://latestbuilds.hq.couchbase.com
    PKG_NAME=couchbase-server-${EDITION}_x86_64_${PKG_VERSION}-${PKG_BUILD_NUM}-rel.zip
    PKG_DIR=couchbase-server-${EDITION}_x86_64_3
fi


if [[ ${DOWNLOAD_NEW_PKG} ]]
then
    curl -O ${PKG_URL}/${PKG_NAME}

    if [[ -d ${PKG_DIR} ]] ; then rm -rf ${PKG_DIR} ; fi
    if [[ -e ${PKG_NAME} ]]
    then
        unzip -qq ${PKG_NAME}
    else
        echo ${PKG_NAME} not found!
        exit 1
    fi
fi

if [[ -d ${PKG_DIR} ]]
then
    pushd ${PKG_DIR} 
else
    mkdir ${PKG_DIR}
    mv *.app ${PKG_DIR}
    mv README.txt ${PKG_DIR}
    pushd ${PKG_DIR} 
fi

sign_flags="--force --verbose --preserve-metadata=identifier,entitlements,requirements"
echo options: $sign_flags -----

echo -------- Must sign Sparkle framework all versions ----------
codesign $sign_flags --sign "Developer ID Application: Couchbase, Inc" Couchbase\ Server.app/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle
codesign $sign_flags --sign "Developer ID Application: Couchbase, Inc" Couchbase\ Server.app/Contents/Frameworks/Sparkle.framework/Versions/A

codesign $sign_flags --sign "Developer ID Application: Couchbase, Inc" Couchbase\ Server.app/Contents/Frameworks/Sparkle.framework/Versions/Current/Sparkle
codesign $sign_flags --sign "Developer ID Application: Couchbase, Inc" Couchbase\ Server.app/Contents/Frameworks/Sparkle.framework/Versions/Current

echo --------- Sign Couchbase app last --------------
codesign $sign_flags --sign "Developer ID Application: Couchbase, Inc" Couchbase\ Server.app

popd

if [[ -e ${PKG_NAME} ]]
then
    mv -f ${PKG_NAME} ${PKG_NAME}.orig
fi

zip -qry ${PKG_NAME} ${PKG_DIR} 

