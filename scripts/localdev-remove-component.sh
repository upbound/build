#!/usr/bin/env bash
set -aeuo pipefail

COMPONENT=$1

source "${SCRIPTS_DIR}/utils.sh"
source "${SCRIPTS_DIR}/load-configs.sh" "${COMPONENT}"

if [ -z "${HELM_RELEASE_NAME}" ]; then
  HELM_RELEASE_NAME=${COMPONENT}
fi

"${HELM}" delete "${HELM_RELEASE_NAME}" --kubeconfig "${KUBECONFIG}" --purge
