#!/usr/bin/env bash
set -aeuo pipefail

COMPONENT=$1

# Source utility functions
source "${SCRIPTS_DIR}/utils.sh"
# sourcing load-configs.sh:
#   - initializes configuration variables with default values
#   - loads top level configuration
#   - loads component level configuration
source "${SCRIPTS_DIR}/load-configs.sh" "${COMPONENT}"

# Skip deployment of this component if COMPONENT_SKIP_DEPLOY is set to true
if [ "${COMPONENT_SKIP_DEPLOY}" == "true" ]; then
  echo "COMPONENT_SKIP_DEPLOY set to true, skipping deployment of ${COMPONENT}"
  exit 0
fi

if [ "${USE_HELM3}" == "true" ]; then
  HELM="${HELM3}"
  XDG_DATA_HOME="${HELM_HOME}"
  XDG_CONFIG_HOME="${HELM_HOME}"
  XDG_CACHE_HOME="${HELM_HOME}"
fi

# if HELM_CHART_NAME is not set, default to component name
if [ -z "${HELM_CHART_NAME}" ]; then
  HELM_CHART_NAME="${COMPONENT}"
fi

registries_arr=($BUILD_REGISTRIES)
images_arr=($BUILD_IMAGES)
image_archs_arr=($BUILD_IMAGE_ARCHS)
charts_arr=($BUILD_HELM_CHARTS_LIST)

if [ "${LOCAL_BUILD}" == "true" ] && containsElement "${HELM_CHART_NAME}" ${charts_arr[@]+"${charts_arr[@]}"}; then
  # If local build is set and helm chart is from this repository, use locally build helm chart tgz file.
  echo "Deploying locally built artifacts..."
  HELM_CHART_VERSION=${BUILD_HELM_CHART_VERSION}
  HELM_CHART_REF="${HELM_OUTPUT_DIR}/${COMPONENT}-${HELM_CHART_VERSION}.tgz"
  [ -f "${HELM_CHART_REF}" ] || echo_error "Local chart ${HELM_CHART_REF} not found. Did you run \"make build\" ? "

  # If local build, tag "required" local images, so that they can be load into kind cluster at a later step.
  for r in "${registries_arr[@]}"; do
    for i in "${images_arr[@]}"; do
      for a in "${image_archs_arr[@]}"; do
        if containsElement "${r}/${i}" "${REQUIRED_IMAGES[@]}"; then
          echo "Tagging locally built image as ${r}/${i}:${VERSION}"
          docker tag "${BUILD_REGISTRY}/${i}-${a}" "${r}/${i}:${VERSION}"
        fi
      done
    done
  done
else
  # If local build is NOT set or helm chart is NOT from this repository, deploy chart from a remote repository.
  echo "Deploying latest artifacts in chart repo \"${HELM_REPOSITORY_NAME}\"..."
  if [ -z ${HELM_REPOSITORY_NAME} ] || [ -z ${HELM_CHART_NAME} ]; then
    echo_error "HELM_REPOSITORY_NAME and/or HELM_CHART_NAME is not set for component ${COMPONENT}!"
  fi
  HELM_CHART_REF="${HELM_REPOSITORY_NAME}/${HELM_CHART_NAME}"
  # Add helm repo and update repositories, if repo is not added already or force update is set.
  if [ "${HELM_REPOSITORY_FORCE_UPDATE}" == "true" ] || ! "${HELM}" repo list -o yaml |grep -i "Name:\s*${HELM_REPOSITORY_NAME}\s*$" >/dev/null; then
    "${HELM}" repo add "${HELM_REPOSITORY_NAME}" "${HELM_REPOSITORY_URL}"
    "${HELM}" repo update
  fi
  if [ -z "${HELM_CHART_VERSION}" ]; then
    # if no HELM_CHART_VERSION provided, then get the latest version from repo which will be used to load required images for chart.
    HELM_CHART_VERSION=$("${HELM}" search -l ${HELM_CHART_REF} --devel |awk 'NR==2{print $2}')
    echo "Latest version found in repo: ${HELM_CHART_VERSION}"
  fi
  if [ -z "${HELM_CHART_VERSION}" ]; then
    echo_error "No version found in repo for chart ${HELM_CHART_REF}"
  fi
fi

# shellcheck disable=SC2068
for i in ${REQUIRED_IMAGES[@]+"${REQUIRED_IMAGES[@]}"}; do
  # check if image has a tag, if not, append tag for the chart
  if ! echo "${i}" | grep ":"; then
    i="${i}:v${HELM_CHART_VERSION}"
  fi
  # Pull the image:
  # - if has a tag "master" or "latest"
  # - or does not exist already.
  if echo "${i}" | grep ":master\s*$" >/dev/null || echo "${i}" | grep ":latest\s*$" >/dev/null || ! docker inspect --type=image "${i}" >/dev/null 2>&1; then
    docker pull "${i}"
  fi
  "${KIND}" load docker-image "${i}" --name="${KIND_CLUSTER_NAME}"
done


PREDEPLOY_SCRIPT="${DEPLOY_LOCAL_CONFIG_DIR}/${COMPONENT}/pre-deploy.sh"
POSTDEPLOY_SCRIPT="${DEPLOY_LOCAL_CONFIG_DIR}/${COMPONENT}/post-deploy.sh"

# Run config.validate.sh if exists.
test -f "${DEPLOY_LOCAL_CONFIG_DIR}/config.validate.sh" && source "${DEPLOY_LOCAL_CONFIG_DIR}/config.validate.sh"

# Create the HELM_RELEASE_NAMESPACE if not exist already.
"${KUBECTL}" --kubeconfig "${KUBECONFIG}" get ns "${HELM_RELEASE_NAMESPACE}" >/dev/null 2>&1 || ${KUBECTL} \
  --kubeconfig "${KUBECONFIG}" create ns "${HELM_RELEASE_NAMESPACE}"

# Run pre-deploy script, if exists.
if [ -f "${PREDEPLOY_SCRIPT}" ]; then
  echo "Running pre-deploy script..."
  source "${PREDEPLOY_SCRIPT}"
fi

# With all configuration sourced as environment variables, render value-overrides.yaml file with gomplate.
"${GOMPLATE}" -f "${DEPLOY_LOCAL_CONFIG_DIR}/${COMPONENT}/value-overrides.yaml.tmpl" \
  -o "${DEPLOY_LOCAL_CONFIG_DIR}/${COMPONENT}/value-overrides.yaml"

helm_chart_version_flag="--devel"
if [ -n "${HELM_CHART_VERSION}" ]; then
  helm_chart_version_flag="--version ${HELM_CHART_VERSION}"
fi

helm_wait_atomic_flag="--wait"
if [ "${HELM_DELETE_ON_FAILURE}" == "true" ]; then
  helm_wait_atomic_flag="--atomic"
fi

# if HELM_RELEASE_NAME is not set, default to component name
if [ -z "${HELM_RELEASE_NAME}" ]; then
  HELM_RELEASE_NAME=${COMPONENT}
fi

# Run helm upgrade --install with computed parameters.
# shellcheck disable=SC2086
set -x
"${HELM}" upgrade --install "${HELM_RELEASE_NAME}" --namespace "${HELM_RELEASE_NAMESPACE}" --kubeconfig "${KUBECONFIG}" \
  "${HELM_CHART_REF}" ${helm_chart_version_flag:-} -f "${DEPLOY_LOCAL_CONFIG_DIR}/${COMPONENT}/value-overrides.yaml" \
 ${helm_wait_atomic_flag:-}
{ set +x; } 2>/dev/null

# Run post-deploy script, if exists.
if [ -f "${POSTDEPLOY_SCRIPT}" ]; then
  echo "Running post-deploy script..."
  source "${POSTDEPLOY_SCRIPT}"
fi