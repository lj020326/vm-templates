#!/bin/bash -eux

set -e
set -x

VENV_DIR_DEFAULT="${HOME}/.venv/ansible"

__VENV_DIR="${VENV_DIR:-"${VENV_DIR_DEFAULT}"}"
__PIP_INSTALL_VERSION="${PIP_INSTALL_VERSION:-"latest"}"

## ref: https://liquidat.wordpress.com/2019/08/30/howto-get-a-python-virtual-environment-running-on-rhel-8/
echo "==> Create virtual environment [${__VENV_DIR}] with pip version '${__PIP_INSTALL_VERSION}'"
#python3 -m venv "${__VENV_DIR}"
#python3 -m venv --system-site-packages "${__VENV_DIR}"
python3 -m venv --upgrade "${__VENV_DIR}"

PYTHON_CMD="${__VENV_DIR}/bin/python3"

#PIP_INSTALL_CMD_USER="${__VENV_DIR}/bin/pip3 install --user --upgrade --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org"
#PIP_INSTALL_CMD="${__VENV_DIR}/bin/pip3 install --upgrade --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org"

#PIP_INSTALL_CMD_USER="${__VENV_DIR}/bin/pip3 install --user --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org"
PIP_INSTALL_CMD="${__VENV_DIR}/bin/pip3 install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org"

## ref: https://stackoverflow.com/questions/6141581/detect-python-version-in-shell-script#6141633
PYTHON_VERSION=$(${PYTHON_CMD} -c 'import sys; version=sys.version_info[:2]; print("{0}.{1}".format(*version))')

echo "==> Install latest ansible"
### ref: http://www.freekb.net/Article?id=214
### ref: https://github.com/pyca/pyopenssl/issues/559
##${PIP_INSTALL_CMD} pip ansible virtualenv cryptography pyopenssl
##${PIP_INSTALL_CMD} pip ansible cryptography pyopenssl
${PIP_INSTALL_CMD} wheel
#${PIP_INSTALL_CMD} setuptools_rust
##${PIP_INSTALL_CMD} cryptography
##${PIP_INSTALL_CMD} pyopenssl

if [ "${__PIP_INSTALL_VERSION}" == "latest" ]; then
  if [ -e "${__VENV_DIR}/bin/pip3" ] > /dev/null; then
    echo "==> Run [${PIP_INSTALL_CMD} --upgrade pip]"
    ${PIP_INSTALL_CMD} --upgrade pip
  else
    ## ref: https://stackoverflow.com/questions/65985221/pip-upgrade-issue-using-python-m-pip-install-upgrade-pip
    GET_PIP_URL="https://bootstrap.pypa.io/get-pip.py"
    case "${PYTHON_VERSION}" in
      *3.6* | *2.7*)
        GET_PIP_URL="https://bootstrap.pypa.io/pip/${PYTHON_VERSION}/get-pip.py"
        ${PYTHON_CMD} /tmp/get-pip.py
        ;;
      *)
        GET_PIP_URL="https://bootstrap.pypa.io/get-pip.py"
        ${PYTHON_CMD} /tmp/get-pip.py
    esac
#    wget -O /tmp/get-pip.py --no-verbose --no-check-certificate "${GET_PIP_URL}"
    curl -ks -o /tmp/get-pip.py "${GET_PIP_URL}"
    ${PYTHON_CMD} /tmp/get-pip.py
    ${PIP_INSTALL_CMD} --upgrade pip
  fi
else
  ${PIP_INSTALL_CMD} --upgrade pip=="${__PIP_INSTALL_VERSION}"
fi

${PIP_INSTALL_CMD} ansible

########
## pip libs required for dcc_common.util.apply_common_group
PIP_LIB_LIST=()
PIP_LIB_LIST+=("netaddr")
PIP_LIB_LIST+=("jmespath")
PIP_LIB_LIST+=("passlib")

echo "==> Install additional pip libs required by private collections]"
#${PIP_INSTALL_CMD} netaddr jmespath
eval "${PIP_INSTALL_CMD} ${PIP_LIB_LIST[*]}"

#echo "export PATH=$PATH:~/.local/bin" >> ~/.bash_profile

#echo "==> Install upgraded ansible collections"
#export PATH=$PATH:/usr/local/bin
#ansible-galaxy collection install -U ansible.utils
#ansible-galaxy collection install -U community.general

if [[ ! -z ${ANSIBLE_VAULT_PASS+x} ]]; then
  echo "==> Setup ansible ~/.vault_pass"
  echo "${ANSIBLE_VAULT_PASS}" > ~/.vault_pass
  chmod 600 ~/.vault_pass
fi
