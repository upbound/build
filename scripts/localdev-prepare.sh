#!/usr/bin/env bash
set -aeuo pipefail

# Source utility functions
source "${SCRIPTS_DIR}/utils.sh"

if [ -n "${LOCAL_DEV_REPOS}" ]; then
  # prepare local dev configuration under ".work/local" by gathering configuration from different repositories.
  LOCALDEV_WORKDIR=${WORK_DIR}/local

  mkdir -p "${LOCALDEV_WORKDIR}"

  # if a local dev integration config repo configured
  LOCALDEV_WORKDIR_REPOS=${LOCALDEV_WORKDIR}/repos

  repositories_arr=($LOCAL_DEV_REPOS)
  for i in ${repositories_arr[@]+"${repositories_arr[@]}"}; do

    local_repo=$(basename $(git config --get remote.origin.url) .git)
    repo=$(basename "${i}" .git)

    if [ "${LOCAL_BUILD}" == "true" ] && [ "${repo}" == "${local_repo}" ]; then
      # if it is a local build and repo is the local one, just use local config

      echo "Using local config for repo \"${repo}\""
      repo_dir="${ROOT_DIR}"
    else
      # otherwise, shallow clone the repo
      repo_dir=${LOCALDEV_WORKDIR_REPOS}/${repo}

      repo_url="git@github.com:${i}.git"
      if [ "${LOCALDEV_CLONE_WITH}" == "https" ]; then
        repo_url="https://github.com/${i}.git"
      fi
      # only clone if not cloned already.
      test -d "${repo_dir}" || { echo "Cloning repo ${repo} to get local dev config"; git clone --depth 1 "${repo_url}" "${repo_dir}"; }
    fi

    # copy local dev config under workdir
    # TODO(hasan): `cluster/local/config` should not be hardcoded, should be part of repo configuration somehow (repos.env)
    if [ -d ${repo_dir}/cluster/local/config ]; then
      cp -rf "${repo_dir}/cluster/local/config/." "${DEPLOY_LOCAL_WORKDIR}/config"
    else
      echo_warn "No local dev config found for repo \"${repo}\""
    fi
  done
fi