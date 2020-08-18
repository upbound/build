#!/usr/bin/env bash
set -aeuo pipefail

COMPONENT=$1

source "${SCRIPTS_DIR}/utils.sh"
source "${SCRIPTS_DIR}/load-configs.sh" "${COMPONENT}"

if [ -z "${HELM_RELEASE_NAME}" ]; then
  HELM_RELEASE_NAME=${COMPONENT}
fi

helm_purge_flag="--purge"
if [ "${USE_HELM3}" == "true" ]; then
  HELM="${HELM3}"
  XDG_DATA_HOME="${HELM_HOME}"
  XDG_CONFIG_HOME="${HELM_HOME}"
  XDG_CACHE_HOME="${HELM_HOME}"
  helm_purge_flag=""
fi

set -x
"${HELM}" delete "${HELM_RELEASE_NAME}" --kubeconfig "${KUBECONFIG}" ${helm_purge_flag}
{ set +x; } 2>/dev/null