# File: .fries/lib/openshift_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.10.25
# Project Page: https://github.com/landonb/home-fries
# Summary: OpenShift Helpers.
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

oc-rsh-mysql () {

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
        MYSQL_POD=$(oc get pods | grep "^mysql-" | awk '{print $1}')
        refreshed_pod_name=true
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
      echo '  oc get pods | grep "^mysql-" | awk "{print $1}"'
      return 1
    fi

    echo "Trying \`oc rsh ${MYSQL_POD}\`"
    oc rsh ${MYSQL_POD}
    if [[ $? -ne 0 ]]; then
        if ! $refreshed_pod_name; then
            MYSQL_POD=$(oc get pods | grep "^mysql-" | awk '{print $1}')
            echo "Trying \`oc rsh ${MYSQL_POD}\`"
            oc rsh ${MYSQL_POD}
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

    TARGET_POD=$(oc get pods | grep "^$1-" | grep Running | awk '{print $1}')

    echo "Trying \`oc rsh ${TARGET_POD}\`"
    oc rsh ${TARGET_POD}
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Unable to \`oc rsh\` to pod: ${MYSQL_POD}"
    fi

}

