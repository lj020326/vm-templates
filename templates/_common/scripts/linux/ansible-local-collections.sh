#!/bin/bash -eux

TMP_COLLECTIONS_DIR="/tmp/ansible_collections"

echo "==> Setup ansible ansible_bitbucket.key"
mkdir -p -m0700 ~/.ssh/
#echo "==> ANSIBLE_BITBUCKET_SSH_KEY_STRING=${ANSIBLE_BITBUCKET_SSH_KEY_STRING}"
echo "${ANSIBLE_BITBUCKET_SSH_KEY_STRING}" > ~/.ssh/ansible_bitbucket.key
chmod 600 ~/.ssh/ansible_bitbucket.key

echo "==> Setup ~/.gitconfig"
## ref: https://stackoverflow.com/questions/7772190/passing-ssh-options-to-git-clone
echo "
[core]
	sshCommand = ssh -i ~/.ssh/ansible_bitbucket.key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
[init]
	defaultBranch = main
" > ~/.gitconfig

## ref: https://stackoverflow.com/questions/600079/how-do-i-clone-a-subdirectory-only-of-a-git-repository
function git_sparse_clone() (
  REMOTE_URL="$1"
  REMOTE_BRANCH="$2"
  LOCAL_DIR="$3"
  shift 3

#  mkdir -p "$LOCAL_DIR"
#  cd "$LOCAL_DIR"
#  git init
#  git remote add -f origin "$REMOTE_URL"
#  git config core.sparseCheckout true
#  # Loops over remaining args
#  for i; do
#    echo "$i" >> .git/info/sparse-checkout
#  done
#  git pull origin "${REMOTE_BRANCH}"

  ## ref: https://stackoverflow.com/questions/4114887/is-it-possible-to-do-a-sparse-checkout-without-checking-out-the-whole-repository
#  git clone --filter=blob:none --no-checkout --depth 1 --sparse "$REMOTE_URL" "$LOCAL_DIR"
  git clone --no-checkout --depth 1 --sparse "$REMOTE_URL" "$LOCAL_DIR"
  cd "$LOCAL_DIR"
  # to fetch only root files
  git sparse-checkout init --cone

  ## ref: https://unix.stackexchange.com/questions/197792/joining-bash-arguments-into-single-string-with-spaces
  git sparse-checkout add "${@}"

  git checkout "${REMOTE_BRANCH}"
)

echo "==> Perform sparse clone of ${ANSIBLE_LOCAL_COLLECTIONS_GIT_URL}"
git_sparse_clone "${ANSIBLE_LOCAL_COLLECTIONS_GIT_URL}" "main" "${TMP_COLLECTIONS_DIR}" "collections"

echo "==> Setup ansible local collections"
mkdir -p "${ANSIBLE_STAGING_DIRECTORY}/galaxy_collections/ansible_collections/"
#cd "${ANSIBLE_STAGING_DIRECTORY}/galaxy_collections/ansible_collections/"

cp -npr "${TMP_COLLECTIONS_DIR}/collections/ansible_collections/dcc_common" \
  "${ANSIBLE_STAGING_DIRECTORY}/galaxy_collections/ansible_collections/"

