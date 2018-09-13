#!/bin/bash -e

# get the build environment variables from the special build.vars target in the main makefile
eval $(make --no-print-directory -C ${scriptdir}/.. build.vars)

KUBEADM_DIND_DIR=${CACHE_DIR}/kubeadm-dind

CROSS_IMAGE=${BUILD_REGISTRY}/cross-amd64
CROSS_IMAGE_VOLUME=cross-volume
CROSS_RSYNC_PORT=10873

function ver() {
    printf "%d%03d%03d%03d" $(echo "$1" | tr '.' ' ')
}

function check_git() {
    # git version 2.6.6+ through 2.8.3 had a bug with submodules. this makes it hard
    # to share a cloned directory between host and container
    # see https://github.com/git/git/blob/master/Documentation/RelNotes/2.8.3.txt#L33
    local gitversion=$(git --version | cut -d" " -f3)
    if (( $(ver ${gitversion}) > $(ver 2.6.6) && $(ver ${gitversion}) < $(ver 2.8.3) )); then
        echo WARN: your running git version ${gitversion} which has a bug realted to relative
        echo WARN: submodule paths. Please consider upgrading to 2.8.3 or later
    fi
}

function start_rsync_container() {
    docker run \
        -d \
        -e OWNER=root \
        -e GROUP=root \
        -e MKDIRS="/volume/go/src/${PROJECT_REPO}" \
        -p ${CROSS_RSYNC_PORT}:873 \
        -v ${CROSS_IMAGE_VOLUME}:/volume \
        --entrypoint "/tini" \
        ${CROSS_IMAGE} \
        -- /build/rsyncd.sh
}

function wait_for_rsync() {
    # wait for rsync to come up
    local tries=100
    while (( ${tries} > 0 )) ; do
        if rsync "rsync://localhost:${CROSS_RSYNC_PORT}/"  &> /dev/null ; then
            return 0
        fi
        tries=$(( ${tries} - 1 ))
        sleep 0.1
    done
    echo ERROR: rsyncd did not come up >&2
    exit 1
}

function stop_rsync_container() {
    local id=$1

    docker stop ${id} &> /dev/null || true
    docker rm ${id} &> /dev/null || true
}

function run_rsync() {
    local src=$1
    shift

    local dst=$1
    shift

    # run the container as an rsyncd daemon so that we can copy the
    # source tree to the container volume.
    local id=$(start_rsync_container)

    # wait for rsync to come up
    wait_for_rsync || stop_rsync_container ${id}

    # NOTE: add --progress to show files being syncd
    rsync \
        --archive \
        --delete \
        --prune-empty-dirs \
        "$@" \
        $src $dst || { stop_rsync_container ${id}; return 1; }

    stop_rsync_container ${id}
}

function rsync_host_to_container() {
    run_rsync ${scriptdir}/.. rsync://localhost:${CROSS_RSYNC_PORT}/volume/go/src/${PROJECT_REPO} "$@"
}

function rsync_container_to_host() {
    run_rsync rsync://localhost:${CROSS_RSYNC_PORT}/volume/go/src/${PROJECT_REPO}/ ${scriptdir}/.. "$@"
}
