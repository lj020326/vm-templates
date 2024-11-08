#!/bin/bash -eux

set -e
set -x

#PYENV_ROOT_DEFAULT="${HOME}/.pyenv"
PYENV_ROOT_DEFAULT="/opt/pyenv"
__PYENV_ROOT="${PYENV_ROOT:-"${PYENV_ROOT_DEFAULT}"}"

#PYTHON_VERSION="3.11.9"
PYTHON_VERSION="3.12.3"

####################
## pyenv
#WORKDIR $HOME

## ref: https://github.com/pyenv/pyenv?tab=readme-ov-file#installation
## ref: https://github.com/pyenv/pyenv-installer?tab=readme-ov-file
#git clone --depth=1 https://github.com/pyenv/pyenv.git .pyenv
#git clone --depth=1 https://github.com/pyenv/pyenv.git /opt/pyenv
#curl https://pyenv.run | bash
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

PATH="$__PYENV_ROOT/shims:$__PYENV_ROOT/bin:$PATH"

## ref: https://github.com/pyenv/pyenv/issues/2416#issuecomment-1219484906
## ref: https://github.com/pyenv/pyenv/issues/2760#issuecomment-1868608898
## ref: https://stackoverflow.com/questions/57743230/userwarning-could-not-import-the-lzma-module-your-installed-python-is-incomple#57773679
## ref: https://superuser.com/questions/1346141/how-to-link-python-to-the-manually-compiled-openssl-rather-than-the-systems-one
## ref: https://github.com/pyenv/pyenv/issues/2416
#env CPPFLAGS="-I/usr/include/openssl" LDFLAGS="-L/usr/lib64/openssl -lssl -lcrypto" CFLAGS=-fPIC \
#env CPPFLAGS="-I/usr/include/openssl11/openssl" LDFLAGS="-L/usr/lib64/openssl -lssl -lcrypto" CFLAGS=-fPIC \
#CPPFLAGS=$(pkg-config --cflags openssl) LDFLAGS=$(pkg-config --libs openssl) \
pyenv install $PYTHON_VERSION
#pyenv global $PYTHON_VERSION
#pyenv rehash
eval "$(/opt/pyenv/bin/pyenv init -)" && /opt/pyenv/bin/pyenv local $PYTHON_VERSION

## ref: https://www.baeldung.com/ops/dockerfile-path-environment-variable
echo "export PATH=$__PYENV_ROOT/shims:$__PYENV_ROOT/bin:$PATH" >> ~/.bashrc

#echo "export PATH=$PATH:~/.local/bin" >> ~/.bash_profile

if [[ ! -z ${ANSIBLE_VAULT_PASS+x} ]]; then
  echo "==> Setup ansible ~/.vault_pass"
  echo "${ANSIBLE_VAULT_PASS}" > ~/.vault_pass
  chmod 600 ~/.vault_pass
fi
