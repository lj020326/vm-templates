#!/usr/bin/env bash

## ref: https://stackoverflow.com/questions/3685548/java-keytool-easy-way-to-add-server-cert-from-url-port
## ref: https://superuser.com/questions/97201/how-to-save-a-remote-server-ssl-certificate-locally-as-a-file
## ref: https://serverfault.com/questions/661978/displaying-a-remote-ssl-certificate-details-using-cli-tools

#set -x

VERSION="2025.3.2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "SCRIPT_DIR=[${SCRIPT_DIR}]"

SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME="${SCRIPT_NAME%.*}"
logFile="${SCRIPT_NAME}.log"

INSTALL_JDK_CACERT=1
INSTALL_DOCKER_CACERT=0
SETUP_PYTHON_CACERTS_ONLY=0

SITE_LIST_DEFAULT=()
#SITE_LIST_DEFAULT+=("media.johnson.int:5000")
#SITE_LIST_DEFAULT+=("media.johnson.int")
#SITE_LIST_DEFAULT+=("admin.dettonville.int")
#SITE_LIST_DEFAULT+=("pypi.python.org")
#SITE_LIST_DEFAULT+=("files.pythonhosted.org")
#SITE_LIST_DEFAULT+=("bootstrap.pypa.io")
#SITE_LIST_DEFAULT+=("galaxy.ansible.com")
SITE_LIST_DEFAULT+=("admin.dettonville.int")

KEYTOOL=keytool
USER_KEYSTORE="${HOME}/.keystore"

## https://stackoverflow.com/questions/26988262/best-way-to-find-the-os-name-and-version-on-a-unix-linux-platform#26988390
UNAME=$(uname -s | tr "[:upper:]" "[:lower:]")
PLATFORM=""
DISTRO=""

CACERT_TRUST_DIR=/etc/pki/ca-trust/extracted
CACERT_TRUST_IMPORT_DIR=/etc/pki/ca-trust/source/anchors
CACERT_BUNDLE=${CACERT_TRUST_DIR}/openssl/ca-bundle.trust.crt
CACERT_TRUST_FORMAT="pem"

## ref: https://askubuntu.com/questions/459402/how-to-know-if-the-running-platform-is-ubuntu-or-centos-with-help-of-a-bash-scri
case "${UNAME}" in
    linux*)
      if type "lsb_release" > /dev/null 2>&1; then
        LINUX_OS_DIST=$(lsb_release -a | tr "[:upper:]" "[:lower:]")
      else
        LINUX_OS_DIST=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr "[:upper:]" "[:lower:]")
      fi
      PLATFORM=Linux
      case "${LINUX_OS_DIST}" in
        *ubuntu* | *debian*)
          # Debian Family
          #CACERT_TRUST_DIR=/usr/ssl/certs
          CACERT_TRUST_DIR=/etc/ssl/certs
          CACERT_TRUST_IMPORT_DIR=/usr/local/share/ca-certificates
          CACERT_BUNDLE=${CACERT_TRUST_DIR}/ca-certificates.crt
          DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
          CACERT_TRUST_COMMAND="update-ca-certificates"
          CACERT_TRUST_FORMAT="crt"
          ;;
        *redhat* | *"red hat"* | *centos* | *fedora* )
          # RedHat Family
          CACERT_TRUST_DIR=/etc/pki/tls/certs
          #CACERT_TRUST_IMPORT_DIR=/etc/pki/ca-trust/extracted/openssl
          #CACERT_BUNDLE=${CACERT_TRUST_DIR}/ca-bundle.trust.crt
          #CACERT_TRUST_DIR=/etc/pki/ca-trust/extracted/pem
          CACERT_TRUST_IMPORT_DIR=/etc/pki/ca-trust/source/anchors
          #CACERT_BUNDLE=${CACERT_TRUST_DIR}/tls-ca-bundle.pem
          CACERT_BUNDLE=${CACERT_TRUST_DIR}/ca-bundle.trust.crt
          DISTRO=$(cat /etc/system-release)
          CACERT_TRUST_COMMAND="update-ca-trust extract"
          CACERT_TRUST_FORMAT="pem"
          ;;
        *)
          # Otherwise, use release info file
          CACERT_TRUST_DIR=/usr/ssl/certs
          CACERT_TRUST_IMPORT_DIR=/etc/pki/ca-trust/source/anchors
          CACERT_BUNDLE=${CACERT_TRUST_DIR}/ca-bundle.crt
          DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
          CACERT_TRUST_COMMAND="update-ca-certificates"
          CACERT_TRUST_FORMAT="pem"
      esac
      ;;
    darwin*)
      PLATFORM=DARWIN
      CACERT_TRUST_DIR=/etc/ssl
      CACERT_TRUST_IMPORT_DIR=/usr/local/share/ca-certificates
      CACERT_BUNDLE=${CACERT_TRUST_DIR}/cert.pem
      ;;
    cygwin* | mingw64* | mingw32* | msys*)
      PLATFORM=MSYS
      ## https://packages.msys2.org/package/ca-certificates?repo=msys&variant=x86_64
      CACERT_TRUST_DIR=/etc/pki/ca-trust/extracted
      CACERT_TRUST_IMPORT_DIR=/etc/pki/ca-trust/source/anchors
      CACERT_BUNDLE=${CACERT_TRUST_DIR}/openssl/ca-bundle.trust.crt
      ;;
    *)
      PLATFORM="UNKNOWN:${UNAME}"
esac

#### LOGGING RELATED
LOG_ERROR=0
LOG_WARN=1
LOG_INFO=2
LOG_TRACE=3
LOG_DEBUG=4

declare -A LOGLEVEL_TO_STR
LOGLEVEL_TO_STR["${LOG_ERROR}"]="ERROR"
LOGLEVEL_TO_STR["${LOG_WARN}"]="WARN"
LOGLEVEL_TO_STR["${LOG_INFO}"]="INFO"
LOGLEVEL_TO_STR["${LOG_TRACE}"]="TRACE"
LOGLEVEL_TO_STR["${LOG_DEBUG}"]="DEBUG"

function reverse_array() {
  local -n ARRAY_SOURCE_REF=$1
  local -n REVERSED_ARRAY_REF=$2
  # Iterate over the keys of the LOGLEVEL_TO_STR array
  for KEY in "${!ARRAY_SOURCE_REF[@]}"; do
    # Get the value associated with the current key
    VALUE="${ARRAY_SOURCE_REF[$KEY]}"
    # Add the reversed key-value pair to the REVERSED_ARRAY_REF array
    REVERSED_ARRAY_REF[$VALUE]="$KEY"
  done
}

declare -A LOGLEVELSTR_TO_LEVEL
reverse_array LOGLEVEL_TO_STR LOGLEVELSTR_TO_LEVEL

#LOG_LEVEL=${LOG_DEBUG}
LOG_LEVEL=${LOG_INFO}

function logError() {
  if [ $LOG_LEVEL -ge $LOG_ERROR ]; then
  	logMessage "${LOG_ERROR}" "${1}"
  fi
}
function logWarn() {
  if [ $LOG_LEVEL -ge $LOG_WARN ]; then
  	logMessage "${LOG_WARN}" "${1}"
  fi
}
function logInfo() {
  if [ $LOG_LEVEL -ge $LOG_INFO ]; then
  	logMessage "${LOG_INFO}" "${1}"
  fi
}
function logTrace() {
  if [ $LOG_LEVEL -ge $LOG_TRACE ]; then
  	logMessage "${LOG_TRACE}" "${1}"
  fi
}
function logDebug() {
  if [ $LOG_LEVEL -ge $LOG_DEBUG ]; then
  	logMessage "${LOG_DEBUG}" "${1}"
  fi
}
function abort() {
  logError "$@"
  exit 1
}
function fail() {
  logError "$@"
  exit 1
}

function logMessage() {
  local LOG_MESSAGE_LEVEL="${1}"
  local LOG_MESSAGE="${2}"
  ## remove first item from FUNCNAME array
#  local CALLING_FUNCTION_ARRAY=("${FUNCNAME[@]:2}")
  ## Get the length of the array
  local CALLING_FUNCTION_ARRAY_LENGTH=${#FUNCNAME[@]}
  local CALLING_FUNCTION_ARRAY=("${FUNCNAME[@]:2:$((CALLING_FUNCTION_ARRAY_LENGTH - 3))}")
#  echo "CALLING_FUNCTION_ARRAY[@]=${CALLING_FUNCTION_ARRAY[@]}"

  local CALL_ARRAY_LENGTH=${#CALLING_FUNCTION_ARRAY[@]}
  local REVERSED_CALL_ARRAY=()
  for (( i = CALL_ARRAY_LENGTH - 1; i >= 0; i-- )); do
    REVERSED_CALL_ARRAY+=( "${CALLING_FUNCTION_ARRAY[i]}" )
  done
#  echo "REVERSED_CALL_ARRAY[@]=${REVERSED_CALL_ARRAY[@]}"

#  local CALLING_FUNCTION_STR="${CALLING_FUNCTION_ARRAY[*]}"
  ## ref: https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-a-bash-array-into-a-delimited-string#17841619
  local SEPARATOR=":"
  local CALLING_FUNCTION_STR
  CALLING_FUNCTION_STR=$(printf "${SEPARATOR}%s" "${REVERSED_CALL_ARRAY[@]}")
  CALLING_FUNCTION_STR=${CALLING_FUNCTION_STR:${#SEPARATOR}}

  ## ref: https://stackoverflow.com/a/13221491
  if [ "${LOGLEVEL_TO_STR[${LOG_MESSAGE_LEVEL}]+abc}" ]; then
    LOG_LEVEL_STR="${LOGLEVEL_TO_STR[${LOG_MESSAGE_LEVEL}]}"
  else
    abort "Unknown log level of [${LOG_MESSAGE_LEVEL}]"
  fi

  local LOG_LEVEL_PADDING_LENGTH=5

  local PADDED_LOG_LEVEL
  PADDED_LOG_LEVEL=$(printf "%-${LOG_LEVEL_PADDING_LENGTH}s" "${LOG_LEVEL_STR}")

  local LOG_PREFIX="${CALLING_FUNCTION_STR}():"
  echo -e "[${PADDED_LOG_LEVEL}]: ==> ${LOG_PREFIX} ${LOG_MESSAGE}"
}

function setLogLevel() {
  LOG_LEVEL_STR=$1

  ## ref: https://stackoverflow.com/a/13221491
  if [ "${LOGLEVELSTR_TO_LEVEL[${LOG_LEVEL_STR}]+abc}" ]; then
    LOG_LEVEL="${LOGLEVELSTR_TO_LEVEL[${LOG_LEVEL_STR}]}"
  else
    abort "Unknown log level of [${LOG_LEVEL_STR}]"
  fi

}

function get_java_keystore() {
  ## default jdk location
  if [ -z "$JAVA_HOME" ]; then
    ## ref: https://stackoverflow.com/questions/394230/how-to-detect-the-os-from-a-bash-script
    if [[ "$UNAME" == "darwin"* ]]; then
      JAVA_HOME=$(/usr/libexec/java_home)
    elif [[ "$UNAME" == "cygwin" || "$UNAME" == "msys" ]]; then
      JAVA_HOME=$(/usr/libexec/java_home)
      #        else
      #                # Unknown.
    fi
  fi
  JDK_CERT_DIR=${JAVA_HOME}/lib/security
  if [ ! -d $JDK_CERT_DIR ]; then
    JDK_CERT_DIR=${JAVA_HOME}/jre/lib/security
  fi

  #echo "JDK_CERT_DIR=[$JDK_CERT_DIR]"
  JAVA_CACERTS="$JDK_CERT_DIR/cacerts"

  echo "${JAVA_CACERTS}"
}

function get_host_cert() {
  local HOST=$1
  local PORT=$2
  local CACERTS_SRC=$3

  logInfo "Fetching certs from host:port ${HOST}:${PORT}"

  if [ -z "$HOST" ]; then
    logError "ERROR: Please specify the server name to import the certificate in from, eventually followed by the port number, if other than 443."
    exit 1
  fi

  set -e

  logInfo "**** get_host_cert() START : find ${CACERTS_SRC}/ -name cert*.crt"
  eval "find ${CACERTS_SRC}/ -name cert*.crt"

#  if [ -e "$CACERTS_SRC/$ALIAS.crt" ]; then
#    rm -f "$CACERTS_SRC/$ALIAS.crt"
#  fi
#  if [ -e "$CACERTS_SRC/$ALIAS.pem" ]; then
#    rm -f "$CACERTS_SRC/$ALIAS.pem"
#  fi

  ############
  ## To avoid "ssl alert number 40"
  ## It is usually related to a server with several virtual hosts to serve,
  ## where you need to/should tell which host you want to connect to in order for the TLS handshake to succeed.
  ##
  ## Specify the exact host name you want with -servername parameter.
  ##
  ## ref: https://stackoverflow.com/questions/9450120/openssl-hangs-and-does-not-exit
  ## ref: https://stackoverflow.com/questions/53965049/handshake-failure-ssl-alert-number-40
  logInfo "Fetching *.crt format certs from host:port ${HOST}:${PORT}"
  FETCH_CRT_CERT_COMMAND="echo QUIT | openssl s_client -connect ${HOST}:${PORT} -servername ${HOST} 1>${CACERTS_SRC}/${ALIAS}.crt"
  logInfo "FETCH_CRT_CERT_COMMAND=${FETCH_CRT_CERT_COMMAND}"
  eval "${FETCH_CRT_CERT_COMMAND}"

  logInfo "Fetching *.pem format certs from host:port ${HOST}:${PORT}"
  FETCH_PEM_CERT_COMMAND="echo QUIT | openssl s_client -showcerts -servername ${HOST} -connect ${HOST}:${PORT} </dev/null 2>/dev/null \
  	| openssl x509 -outform PEM > ${CACERTS_SRC}/${ALIAS}.pem"
  logInfo "FETCH_PEM_CERT_COMMAND=${FETCH_PEM_CERT_COMMAND}"
  eval "${FETCH_PEM_CERT_COMMAND}"

  logInfo "find ${CACERTS_SRC}/ -name cert*.crt"
  eval "find ${CACERTS_SRC}/ -name cert*.crt"

  logInfo "Extracting certs from cert chain for ${HOST}:${PORT} "
  ## ref: https://unix.stackexchange.com/questions/368123/how-to-extract-the-root-ca-and-subordinate-ca-from-a-certificate-chain-in-linux
  openssl s_client -showcerts -verify 5 -connect "${HOST}:${PORT}" -servername "${HOST}" </dev/null \
    | awk -v certdir="${CACERTS_SRC}" '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".crt"; print >(certdir "/" out)}' && \
  for cert in ${CACERTS_SRC}/cert*.crt; do
    #    nameprefix=$(echo "${cert%.*}")
    nameprefix="${cert%.*}"
#    logInfo "nameprefixfor for cert ${cert} ==> ${nameprefix}"
    newname="${nameprefix}".$(openssl x509 -noout -subject -in $cert | sed -n 's/\s//g; s/^.*CN=\(.*\)$/\1/; s/[ ,.*]/_/g; s/__/_/g; s/^_//g;p')."${CACERT_TRUST_FORMAT}"
#    logInfo "newname for cert ${cert} ==> ${newname}"
    mv "${cert}" "${newname}"
  done

}

function import_jdk_cert() {
  KEYSTORE=$1
  local CACERTS_SRC=$2

  logInfo "Adding certs to keystore at [${KEYSTORE}]"

  if $KEYTOOL -cacerts -list -keystore "$KEYSTORE" -storepass "${KEYSTORE_PASS}" -alias "${ALIAS}" >/dev/null; then
    logInfo "Key with alias ${ALIAS} already found, removing old one..."
    if $KEYTOOL -cacerts -delete -alias "${ALIAS}" -keystore "${KEYSTORE}" -storepass "${KEYSTORE_PASS}" >"${TMP_OUT}"; then
      :
    else
      logError "ERROR: Unable to remove the existing certificate for $ALIAS ($?)"
      cat "${TMP_OUT}"
      exit 1
    fi
  fi

  {
    logInfo "Keytool importing pem formatted cert"
#    KEYTOOL_COMMAND="${KEYTOOL} -import -trustcacerts -noprompt -cacerts \
#      -keystore ${KEYSTORE} \
#      -storepass ${KEYSTORE_PASS} \
#      -alias ${ALIAS} \
#      -file ${CACERTS_SRC}/${ALIAS}.pem"
#      logInfo "KEYTOOL_COMMAND=${KEYTOOL_COMMAND}"
    KEYTOOL_COMMAND="${KEYTOOL} -import -trustcacerts -noprompt \
      -keystore ${KEYSTORE} \
      -storepass ${KEYSTORE_PASS} \
      -alias ${ALIAS} \
      -file ${CACERTS_SRC}/${ALIAS}.pem"
      logInfo "KEYTOOL_COMMAND=${KEYTOOL_COMMAND}"
      ${KEYTOOL_COMMAND}
  } || { # catch
    logError "*** Failed to import pem - so try importing the crt formatted cert instead..."
    logError "Keytool importing crt formatted cert"
    KEYTOOL_COMMAND="${KEYTOOL} -import -trustcacerts -noprompt \
      -keystore ${KEYSTORE} \
      -storepass ${KEYSTORE_PASS} \
      -alias ${ALIAS} \
      -file ${CACERTS_SRC}/${ALIAS}.crt"
      logError "KEYTOOL_COMMAND=${KEYTOOL_COMMAND}"
      ${KEYTOOL_COMMAND}
  }

  #    if ${KEYTOOL} -import -trustcacerts -noprompt -keystore ${KEYSTORE} -storepass ${KEYSTORE_PASS} -alias ${ALIAS} -file ${CACERTS_SRC}/${ALIAS}.pem >$TMP_OUT
  if [ $? ]; then
    :
  else
    logError "ERROR: Unable to import the certificate for $ALIAS ($?)"
    cat $TMP_OUT
    exit 1
  fi

}

install_site_cert() {
  ENDPOINT_CONFIG=$1

  KEYSTORE_PASS=${3:-"changeit"}
  KEYTOOL=keytool

  #DATE=`date +&%%m%d%H%M%S`
  DATE=$(date +%Y%m%d)

  logInfo "ENDPOINT_CONFIG=${ENDPOINT_CONFIG}"

  IFS=':' read -r -a array <<< "${ENDPOINT_CONFIG}"
  HOST=${array[0]}
  PORT=${array[1]:-443}

  logInfo "Running for HOST=[$HOST] PORT=[$PORT] KEYSTORE_PASS=[$KEYSTORE_PASS]..."

  ENDPOINT="${HOST}:${PORT}"
  ALIAS="${HOST}:${PORT}"

  if [[ "$UNAME" == "cygwin" || "$UNAME" == "msys" ]]; then
    ALIAS="${HOST}_${PORT}"
  fi

  ## ref: https://knowledgebase.garapost.com/index.php/2020/06/05/how-to-get-ssl-certificate-fingerprint-and-serial-number-using-openssl-command/
  ## ref: https://stackoverflow.com/questions/13823706/capture-multiline-output-as-array-in-bash
#  CERT_INFO=($(echo QUIT | openssl s_client -connect $HOST:$PORT </dev/null 2>/dev/null | openssl x509 -serial -fingerprint -sha256 -noout | cut -d"=" -f2 | sed s/://g))
  CERT_INFO=($(echo QUIT | openssl s_client -connect "${HOST}:${PORT}" -servername "${HOST}" </dev/null 2>/dev/null | openssl x509 -serial -fingerprint -sha256 -noout | cut -d"=" -f2 | sed s/://g))
  CERT_SERIAL=${CERT_INFO[0]}
  CERT_FINGERPRINT=${CERT_INFO[1]}

  #CACERTS_SRC=${HOME}/.cacerts/$ALIAS/$DATE
  #CACERTS_SRC=${HOME}/.cacerts/$ALIAS/$CERT_SERIAL/$CERT_FINGERPRINT
  CACERTS_SRC=/tmp/.cacerts/$ALIAS/$CERT_SERIAL/$CERT_FINGERPRINT

  logInfo "Recreate tmp cert dir ${CACERTS_SRC}"
  rm -fr "${CACERTS_SRC}"
  mkdir -p "${CACERTS_SRC}"
  logInfo "**** INIT : find ${CACERTS_SRC}/ -name cert*.crt"
  eval "find ${CACERTS_SRC}/ -name cert*.crt"

  TMP_OUT=/tmp/${SCRIPT_NAME}.output

  logInfo "Get host cert for ${HOST}:${PORT}"
  get_host_cert "${HOST}" "${PORT}" "${CACERTS_SRC}"

  if [ "$INSTALL_JDK_CACERT" -ne 0 ]; then
    logInfo "Get default java JDK cacert location"
    #JDK_KEYSTORE=$JDK_CERT_DIR/cacerts
    JDK_KEYSTORE=$(get_java_keystore)

    if [ ! -e "${JDK_KEYSTORE}" ]; then
      logInfo "JDK_KEYSTORE [$JDK_KEYSTORE] not found!"
      exit 1
    else
      logInfo "JDK_KEYSTORE found at [$JDK_KEYSTORE]"
    fi

    ### Now build list of cacert targets to update
    logInfo "updating JDK certs at [$JDK_KEYSTORE]..."
    import_jdk_cert "$JDK_KEYSTORE" "${CACERTS_SRC}"

    # FYI: the default keystore is located in ~/.keystore
    DEFAULT_KEYSTORE="~/.keystore"
    if [ -f $DEFAULT_KEYSTORE ]; then
      logInfo "updating default certs at [$DEFAULT_KEYSTORE]..."
      import_jdk_cert $DEFAULT_KEYSTORE
    fi
  fi

  logInfo "Adding cert to the system keychain.."
  if [[ "$UNAME" == "darwin"* ]]; then
#    logInfo "Adding cert to macOS system keychain"
#    #    sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" "/private/tmp/securly_SHA-256.crt"
#    sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" ${CACERTS_SRC}/${ALIAS}.crt

    logInfo "Adding site cert to the current user's trust cert chain"
#    sudo security add-trusted-cert -d -r trustRoot -k "${HOME}/Library/Keychains/login.keychain" ${CACERTS_SRC}/${ALIAS}.crt

    # shellcheck disable=SC2206
    certs=(${CACERTS_SRC}/cert*.pem)
    ca_root_cert=${certs[-1]}
    logInfo "Add the site root cert to the current user's trust cert chain ==> [${ca_root_cert}]"

    MACOS_CACERT_TRUST_COMMAND="security add-trusted-cert -d -r trustRoot -k ${HOME}/Library/Keychains/login.keychain ${ca_root_cert}"
    logInfo "MACOS_CACERT_TRUST_COMMAND=${MACOS_CACERT_TRUST_COMMAND}"
    eval "${MACOS_CACERT_TRUST_COMMAND}"

##    for cert in ${CACERTS_SRC}/cert*.pem; do
##    for ((i=${#files[@]}-1; i>=0; i--)); do
#    certs=(${CACERTS_SRC}/cert*.pem)
#    for ((cert=${#certs[@]}-1; i>=0; i--)); do
#      logInfo "Adding cert to the system keychain ==> [${cert}]"
#      #    nameprefix=$(echo "${cert%.*}")
#      nameprefix="${cert%.*}"
#
#      ## ref: https://apple.stackexchange.com/questions/80623/import-certificates-into-the-system-keychain-via-the-command-line
##      sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" ${cert}
#
#      ## To add to only the current user's trust cert chain
#      sudo security add-trusted-cert -d -r trustRoot -k "${HOME}/Library/Keychains/login.keychain" ${cert}
#
#    done

  elif [[ "$UNAME" == "cygwin" || "$UNAME" == "msys" ]]; then
    ## ref: https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/valid-root-ca-certificates-untrusted
#    ROOT_CERT=$(ls -1 ${CACERTS_SRC}/cert*.pem | sort -nr | head -1)
    ROOT_CERT=$(find ${CACERTS_SRC}/ -name cert*.pem | sort -nr | head -1)

    WIN_CACERT_TRUST_COMMAND="certutil -addstore root ${ROOT_CERT}"
    logInfo "WIN_CACERT_TRUST_COMMAND=${WIN_CACERT_TRUST_COMMAND}"
    eval "${WIN_CACERT_TRUST_COMMAND}"

    ## ref: https://serverfault.com/questions/722563/how-to-make-firefox-trust-system-ca-certificates?newreg=9c67967e3aa248f489c8c9b2cc4ac776
    #certutil -addstore Root ${CERT_DIR}/${HOST}.pem
    ## ref: https://superuser.com/questions/1031444/imPORTing-pem-certificates-on-windows-7-on-the-command-line/1032179
    #certutil –addstore -enterprise –f "Root" "${CERT_DIR}/${HOST}.pem"
    #certutil –addstore -enterprise –f "Root" "${ROOT_CERT}"

  elif [[ "$UNAME" == "linux"* ]]; then
    ROOT_CERT=$(find ${CACERTS_SRC}/ -name cert*.${CACERT_TRUST_FORMAT} | sort -nr | head -1)
    logInfo "copy ROOT_CERT ${ROOT_CERT} to CACERT_TRUST_IMPORT_DIR=${CACERT_TRUST_IMPORT_DIR}"
#    cp -p "${ROOT_CERT}" "${CACERT_TRUST_IMPORT_DIR}/"
    cp -p "${CACERTS_SRC}"/*."${CACERT_TRUST_FORMAT}" "${CACERT_TRUST_IMPORT_DIR}/"
    logInfo "CACERT_TRUST_COMMAND=${CACERT_TRUST_COMMAND}"
    eval "${CACERT_TRUST_COMMAND}"
  fi

  logInfo "**** Finished ****"
}

function usage() {
  echo "Usage: ${0} [options] [[ENDPOINT_CONFIG1] [ENDPOINT_CONFIG2] ...]"
  echo ""
  echo "       ENDPOINT_CONFIG[n] is a colon delimited tuple with SITE_HOSTNAME:SITE_PORT"
  echo ""
  echo "  Options:"
  echo "       -L [ERROR|WARN|INFO|TRACE|DEBUG] : run with specified log level (default INFO)"
  echo "       -v : show script version"
  echo "       -h : help"
  echo "     [TEST_CASES]"
  echo ""
  echo "  Examples:"
	echo "       ${0} "
	echo "       ${0} cacert.example.com,443"
	echo "       ${0} -L DEBUG cacert.example.com,443"
	echo "       ${0} cacert.example.com,443 ca.example.int:443 registry.example.int:5000"
  echo "       ${0} -v"
	[ -z "$1" ] || exit "$1"
}

function main() {
  if [[ "$UNAME" != "cygwin" && "$UNAME" != "msys" ]]; then
    if [ "$EUID" -ne 0 ]; then
      echo "Must run this script as root. run 'sudo $SCRIPT_NAME'"
      exit
    fi
  fi

  while getopts "L:vh" opt; do
      case "${opt}" in
          L) setLogLevel "${OPTARG}" ;;
          v) echo "${VERSION}" && exit ;;
          h) usage 1 ;;
          \?) usage 2 ;;
          *) usage ;;
      esac
  done
  shift $((OPTIND-1))

  local __SITE_LIST=("${SITE_LIST_DEFAULT[@]}")
  if [ $# -gt 0 ]; then
    __SITE_LIST=("$@")
  fi

  logInfo "__SITE_LIST=${__SITE_LIST[*]}"

  logInfo "UNAME=${UNAME}"
  logInfo "LINUX_OS_DIST=${LINUX_OS_DIST}"
  logInfo "PLATFORM=[${PLATFORM}]"
  logInfo "DISTRO=[${DISTRO}]"
  logInfo "CACERT_TRUST_DIR=${CACERT_TRUST_DIR}"
  logInfo "CACERT_TRUST_IMPORT_DIR=${CACERT_TRUST_IMPORT_DIR}"
  logInfo "CACERT_BUNDLE=${CACERT_BUNDLE}"
  logInfo "CACERT_TRUST_COMMAND=${CACERT_TRUST_COMMAND}"

  if [ -d "${CACERT_TRUST_DIR}" ]; then
    logInfo "Remove any broken/invalid sym links from ${CACERT_TRUST_DIR}/"
    find "${CACERT_TRUST_DIR}/" -xtype l -delete
  fi

  logInfo "Add site certs to cacerts"
  IFS=$'\n'

  for ENDPOINT_CONFIG in "${__SITE_LIST[@]}"; do
    logDebug "ENDPOINT_CONFIG=${ENDPOINT_CONFIG}"
    install_site_cert "${ENDPOINT_CONFIG}"
  done
}

main "$@"
