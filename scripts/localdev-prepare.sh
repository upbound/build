#!/usr/bin/env bash
set -aeuo pipefail

# Source utility functions
source "${SCRIPTS_DIR}/utils.sh"

# prepare local dev configuration under ".work/local" by gathering configuration from different repositories.
LOCALDEV_WORKDIR=${WORK_DIR}/local

mkdir -p "${LOCALDEV_WORKDIR}"

if [ -n "${LOCALDEV_INTEGRATION_CONFIG_REPO}" ]; then
  # if a local dev integration config repo configured

  echo "Using integration config from repo ${LOCALDEV_INTEGRATION_CONFIG_REPO}"
  # shallow clone integration config repo, only clone if not already.
  test -d "${DEPLOY_LOCAL_WORKDIR}" || git clone --depth 1 "${LOCALDEV_INTEGRATION_CONFIG_REPO}" "${DEPLOY_LOCAL_WORKDIR}"

  LOCALDEV_WORKDIR_REPOS=${LOCALDEV_WORKDIR}/repos

  # source repo list
  source ${DEPLOY_LOCAL_WORKDIR}/repos.env

  echo "${DEPLOY_LOCAL_REPOS[@]}"
  for i in "${DEPLOY_LOCAL_REPOS[@]}"; do

    local_repo=$(basename $(git config --get remote.origin.url) .git)
    repo=$(basename "${i}" .git)

    if [ "${LOCAL_BUILD}" == "true" ] && [ "${repo}" == "${local_repo}" ]; then
      # if it is a local build and repo is the local one, just use local config

      echo "Using local config for repo ${repo}"
      repo_dir="${ROOT_DIR}"
    else
      # otherwise, shallow clone the repo

      echo "Cloning repo ${repo} to get local dev config"
      repo_dir=${LOCALDEV_WORKDIR_REPOS}/${repo}

      # only clone if not cloned already.
      test -d "${repo_dir}" || git clone --depth 1 ${i} "${repo_dir}"
    fi

    # copy local dev config under workdir
    # TODO(hasan): `cluster/local/config` should not be hardcoded, should be part of repo configuration somehow (repos.env)
    if [ -d ${repo_dir}/cluster/local/config ]; then
      cp -rf "${repo_dir}/cluster/local/config/." "${DEPLOY_LOCAL_WORKDIR}/config"
    else
      echo_warn "No local dev config found for repo ${repo}!"
    fi
  done
else
  # if no local dev integration config repo configured, e.g. localdev only using this repo.

  echo "No integration config repo configured, using local config"
  cp -rf "${DEPLOY_LOCAL_DIR}/." "${DEPLOY_LOCAL_WORKDIR}"
fi