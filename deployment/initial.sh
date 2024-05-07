#!/bin/bash
PORT=${PORT:-8984}
git submodule update --init
yarn install
if [ "${STACK}x" = "x" ]; then
pushd ../../lib/custom
curl -LO https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/9.9.1-8/Saxon-HE-9.9.1-8.jar
curl -LO https://maven.indexdata.com/org/z3950/zing/cql-java/1.13/cql-java-1.13.jar
curl -LO https://repo1.maven.org/maven2/org/xmlresolver/xmlresolver/5.2.3/xmlresolver-5.2.3.jar
popd
if [ "$OSTYPE" == "msys" -o "$OSTYPE" == "win32" ]
then
  pushd ../../bin
  start basexhttp.bat
  popd
else
  pushd ../../bin
  ./basexhttp &
  popd
fi
curl --connect-timeout 5 --max-time 10 --retry 3 --retry-delay 0 --retry-max-time 40 --retry-connrefused 0 -s -D - "http://localhost:8984" -o /dev/null | head -n1 | grep -q '\([23]0[0-9]\)'
else
  source ${1:-../..}/data/credentials
  pushd ${1:-../..}/lib/custom
  curl -LO https://maven.indexdata.com/org/z3950/zing/cql-java/1.13/cql-java-1.13.jar
  popd
fi
pushd deployment
local_password=${BASEX_admin_pw:-admin}
if [ "$local_username"x = x -o "$local_password"x = x ]; then echo "Missing credentials for local BaseX, using admin:${BASEX_admin_pw:-admin}"; local_username=admin; local_password="${BASEX_admin_pw:-admin}"; fi
#------ Settings ---------------------
export USERNAME=$local_username
export PASSWORD=$local_password
#-------------------------------------

curl -LOJ https://arche.acdh.oeaw.ac.at/api/44309

sed -i "s~../webapp/japbib-web/~${BUILD_DIR:-../webapp/japbib-web}/~g" deploy-japbib-web-content.bxs
./execute-basex-batch.sh ${BUILD_DIR:-../webapp/japbib-web}/deployment/deploy-japbib-web-content $1
sed -i "s~../webapp/japbib-web/~${BUILD_DIR:-../webapp/japbib-web}/~g" refresh-cache.xq
./execute-basex-batch.sh ${BUILD_DIR:-../webapp/japbib-web}/deployment/refresh-cache.xq $1