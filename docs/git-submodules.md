
# Submodule information

## How to update submodule(s) to the latest commit

ref: https://stackoverflow.com/questions/8191299/update-a-submodule-to-the-latest-commit

```commandline
$ git submodule update --remote --merge
```

Useful aliases:
```shell
## the `blastit` alias assumes you have a bash function to derive/generate the git comment
## see example: https://github.com/lj020326/ansible-datacenter/blob/main/files/scripts/bashenv/.bash_functions#L350-L364 
$ alias blastit-="git pull origin && git add . && git commit -am $(getgitcomment) && git push origin"
$ alias gitpullsub="git submodule update --recursive --remote"
$ alias gitmergesub="git submodule update --remote --merge && blastit"
## after updates occurred in any submodule repo - invoke gitmergesub will update the repo to latest submodule repo commit
$ gitmergesub
```

refs: 
- https://github.com/lj020326/ansible-datacenter/blob/main/files/scripts/bashenv/.bash_functions#L350-L364
- https://github.com/lj020326/ansible-datacenter/blob/main/files/scripts/bashenv/.bash_aliases#L178


## How to add submodules

```shell
$ git submodule add --name ansible https://github.com/lj020326/ansible-datacenter.git ansible/

```

To specify branches in submodule add:

```shell
$ git submodule add -branch main --name ansible https://github.com/lj020326/ansible-datacenter.git ansible/

```

Reference: https://superuser.com/questions/1600823/whats-the-benefit-of-specifying-a-branch-for-a-submodule

## To enable tracking updates of submodule branches

ref: https://stackoverflow.com/questions/18770545/why-is-my-git-submodule-head-detached-from-master

```shell
$ cd <submodule-path>
$ git checkout <branch>
$ cd <parent-repo-path>
# <submodule-path> is here path releative to parent repo root
# without starting path separator
$ git config -f .gitmodules submodule.<submodule-path>.branch <branch>
$ git config -f .gitmodules submodule.<submodule-path>.update <rebase|merge>
```

```shell

##  setup submodule for ansible 
cd ansible/
git checkout main
cd ..
git config -f .gitmodules submodule.ansible.branch main
git config -f .gitmodules submodule.ansible.update rebase

cat .gitmodules 
gitpullsub
blastit

```

## To add/replace/repair submodule

```shell
$ git switch main
$ git submodule deinit -f .
$ git submodule add --force --name ansible git@bitbucket.org:lj020326/ansible-datacenter.git ansible/
$ git submodule update --init --recursive --remote
$ git add . && git commit -m 'update submodule' && git push
```

## How to rename local submodule directory

Assuming the submodule directory `submodule-dir` is already linked in `.gitmodules` with name `submodule-name`:  

```shell
$ rm -fr submodule-dir/
$ GIT_SSH_COMMAND="ssh -i ~/.ssh/repo_sub.key" git submodule add --force --name submodule-name git@bitbucket.org:lj020326/ansible-datacenter.git new-submodule-dir-name/
```

## To add using specified ssh key for auth

```shell
GIT_SSH_COMMAND="ssh -i ~/.ssh/repo_sub.key" git submodule add --name ansible git@bitbucket.org:lj020326/ansible-datacenter.git ansible/
```

## How to push updates including submodule branch updates:

```shell
$ git submodule update --recursive --remote
$ git add . && git commit -m 'update submodule' && git push
```

## How to change the url for submodule:

ref: https://stackoverflow.com/questions/913701/how-to-change-the-remote-repository-for-a-git-submodule

1) Edit the .gitmodules file to update the URL and then 

2) sync the change to the superproject and your working copy:

    `git submodule sync --recursive`

Should not be necessary with current git versions - but check just in case:

3) go to the .git/modules/path_to_submodule dir and change its config file to update git path.

4) run the following command to apply changes to the repository for the new remote:

```shell
$ git submodule update --recursive --remote
```

```shell
## If first time:
$ git submodule update --init --recursive --remote
```

## How to point to specific submodule branch:

ref: https://stackoverflow.com/questions/1777854/how-can-i-specify-a-branch-tag-when-adding-a-git-submodule

1) Edit the .gitmodules file to add the branch

```ini
[submodule "ansible"]
    path = ansible
    url = git@bitbucket.org:lj020326/ansible-datacenter.git
    branch = main
    update = merge
```

2) run the following command to apply changes to the repository for the new remote:

```shell
$ git submodule update --recursive --remote
```
