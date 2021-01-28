#!/bin/bash

trap "exit 130" SIGINT
trap "exit 137" SIGKILL
trap "exit 143" SIGTERM

set -o errexit
set -o nounset
set -o pipefail

main () {

    DEBUG=${DEBUG:-false}
    if [[ ${DEBUG} == "true" ]]
    then
      set -o xtrace
      CONPOT_DEBUG="-v"
    else
      CONPOT_DEBUG=""
    fi

    # Register this host with CHN if needed
    chn-register.py \
        -p conpot \
        -d "${DEPLOY_KEY}" \
        -u "${CHN_SERVER}" -k \
        -o "${CONPOT_JSON}" \
        -i "${REPORTED_IP}"

    local uid="$(cat ${CONPOT_JSON} | jq -r .identifier)"
    local secret="$(cat ${CONPOT_JSON} | jq -r .secret)"

    # Keep old var names, but create also create some new ones that
    # containedenv can understand

    export CONPOT_hpfriends__host="${FEEDS_SERVER}"
    export CONPOT_hpfriends__port="${FEEDS_SERVER_PORT:-10000}"
    export CONPOT_hpfriends__ident="${uid}"
    export CONPOT_hpfriends__secret="${secret}"
    export CONPOT_hpfriends__tags="${TAGS}"
    if [ ! -z "${REPORTED_IP}" ]
    then
      export CONPOT_hpfriends__reported_ip="${REPORTED_IP}"
    fi

    # Write out custom conpot config
    containedenv-config-writer.py \
      -p CONPOT_ \
      -f ini \
      -r /code/conpot.cfg.template \
      -o /opt/conpot/conpot.cfg

    exec /opt/conpot/conpot/bin/conpot --template ${CONPOT_TEMPLATE:-default} -c /opt/conpot/conpot.cfg -l /var/log/conpot/conpot.log ${CONPOT_DEBUG}
}

main "$@"
