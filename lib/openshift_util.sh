#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# Summary: OpenShift Helpers.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  check_dep 'path_prefix'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_add_to_path_openshift_origin () {
  # OpenShift Origin server.
  [ ! -d "${HOME}/.downloads/openshift-origin-server" ] && return

  path_prefix "${HOME}/.downloads/openshift-origin-server"

  # OpenShift development.
  #  https://github.com/openshift/origin/blob/master/CONTRIBUTING.adoc#develop-locally-on-your-host
  # Used in one place:
  #  /path/to/openshift/origin/hack/common.sh
  export OS_OUTPUT_GOPATH=1
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

oc-rsh-mysql () {
  OC_PROJECT=""
  if [ -n "$1" ]; then
    OC_PROJECT=" -n $1"
  fi

  local token_errmsg="error: You must be logged in to the server (the server has asked for the client to provide credentials)"

  SERIOUSLY_WHO_AM_I=$(oc${OC_PROJECT} whoami 2>&1)
  retcode=$?
  if [ "${SERIOUSLY_WHO_AM_I}" = "${token_errmsg}" ]; then
    echo "ERROR: You need to hit the oauth/token/request endpoint and \`oc login\`."
    return 1
  elif [[ $retcode -ne 0 ]]; then
    echo "WARNING: \`oc${OC_PROJECT} whoami\` failed!"
  fi

  # Get a list of the active project's pods.
  #
  # E.g.,
  #
  #   $ oc get pods
  #   NAME                        READY     STATUS              RESTARTS   AGE
  #   a_container-45-a930o        1/1       Running             0          26d
  #   container_eh-3-build        0/1       Completed           0          55d
  #   a_container-45-a930o        1/1       Running             0          26d
  #   container_eh-3-build        0/1       Completed           0          55d
  #   container_eh-8-smbxn        1/1       Running             0          55d
  #   dude_container-3-build      0/1       Completed           0          55d
  #   dude_container-9-0ktg8      1/1       Running             0          43d
  #   mysql-36-k3k6p              1/1       Running             0          1m
  #   this_container-21-build     0/1       Error               0          1d
  #   this_container-225-176od    1/1       Running             0          2m
  #   this_container-226-deploy   1/1       Running             0          1m

  # Only call get pods if MYSQL_POD not set, or if connect fails.
  refreshed_pod_name=false
  if [[ -z ${MYSQL_POD} ]]; then
    # NOTE: -l app=mysql not working, but name=mysql is.
    # MAYBE: Should we check status is "Running"?
    #MYSQL_POD=$(oc${OC_PROJECT} get pods -l name=mysql | grep "^mysql-" | awk '{print $1}')
    MYSQL_POD=$(oc${OC_PROJECT} get pods -l name=mysql -o json | jq -r '.items[0].metadata.name')
    if [[ -z ${MYSQL_POD} ]]; then
      MYSQL_POD=$(oc${OC_PROJECT} get pods | grep -m 1 "^mysql-" | awk '{print $1}')
    fi
    if [[ -n ${MYSQL_POD} ]]; then
      refreshed_pod_name=true
    fi
  fi

  # FIXME/MAYBE: Connect to mysql database upon login?
  # E.g., in the openshift deployment config, you'll see it has a exec command it runs...
  #      readinessProbe:
  #        exec:
  #          command:
  #          - /bin/sh
  #          - -i
  #          - -c
  #          - MYSQL_PWD="$MYSQL_PASSWORD" mysql -h 127.0.0.1 -u $MYSQL_USER -D $MYSQL_DATABASE
  #            -e 'SELECT 1'

  if [[ -z ${MYSQL_POD} ]]; then
    echo "ERROR: Could not determine pod name. Tried:"
    echo "  oc${OC_PROJECT} get pods -l name=mysql -o json | jq -r '.items[0].metadata.name'"
    echo "and"
    echo "  oc${OC_PROJECT} get pods | grep \"^mysql-\" | awk \"{print $1}\""
    return 1
  fi

  echo "Trying \$(oc${OC_PROJECT} rsh ${MYSQL_POD})"
  oc${OC_PROJECT} rsh ${MYSQL_POD}
  if [[ $? -ne 0 ]]; then
    if ! $refreshed_pod_name; then
      MYSQL_POD=$(oc${OC_PROJECT} get pods | grep -m 1 "^mysql-" | awk '{print $1}')
      echo "Trying \$(oc${OC_PROJECT} rsh ${MYSQL_POD})"
      oc${OC_PROJECT} rsh ${MYSQL_POD}
      if [[ $? -ne 0 ]]; then
        echo "ERROR: Tried twice but unable to \`oc rsh\` to pod: ${MYSQL_POD}"
      fi
    else
      echo "ERROR: Tried once but unable to \`oc rsh\` to pod: ${MYSQL_POD}"
    fi
  fi

  if [[ -n ${MYSQL_POD} ]]; then
    export MYSQL_POD=${MYSQL_POD}
  fi
}

oc-rsh () {
  #POD_NAME=$(oc get pods | grep "^$1-" | grep Running | awk '{print $1}')
  # NOTE: Unlike with the mysql pod, here we use app=, not name=.
  #       Not sure why; I thought the configs all had app= annotations/labels.
  POD_NAME=$( \
    oc get pods -l app=$1 -o json \
    | jq -r '.items[] | select(.status.phase | contains("Running")) | .metadata.name' \
  )

  echo "Trying \$(oc rsh ${POD_NAME})"
  oc rsh ${POD_NAME}
  if [[ $? -ne 0 ]]; then
    echo "ERROR: Unable to \`oc rsh\` to pod: ${MYSQL_POD}"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps

  home_fries_add_to_path_openshift_origin
  unset -f home_fries_add_to_path_openshift_origin
}

main "$@"
unset -f main

