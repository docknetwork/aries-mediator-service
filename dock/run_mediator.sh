#!/bin/bash

if [[ "${ENV}" == "local" ]]; then
    NGROK_NAME=${NGROK_NAME:-ngrok}
    echo "using ngrok end point [$NGROK_NAME]"

    ACAPY_ENDPOINT=null
    while [ -z "$ACAPY_ENDPOINT" ] || [ "$ACAPY_ENDPOINT" = "null" ]
    do
        echo "Fetching end point from ngrok service [$NGROK_NAME:4040/api/tunnels]"
        ACAPY_ENDPOINT=$(curl --silent "$NGROK_NAME:4040/api/tunnels" | ./jq -r '.tunnels[] | select(.proto=="https") | .public_url')

        if [ -z "$ACAPY_ENDPOINT" ] || [ "$ACAPY_ENDPOINT" = "null" ]; then
            echo "ngrok not ready, sleeping 5 seconds...."
            sleep 5
        fi
    done

    NGROK_WS_NAME=${NGROK_WS_NAME:-ngrok_ws}
    echo "using ngrok end point [$NGROK_WS_NAME]"

    ACAPY_WSENDPOINT=null
    while [ -z "$ACAPY_WSENDPOINT" ] || [ "$ACAPY_WSENDPOINT" = "null" ]
    do
        echo "Fetching end point from ngrok service [$NGROK_WS_NAME:4040/api/tunnels]"
        ACAPY_WSENDPOINT=$(curl --silent "$NGROK_WS_NAME:4040/api/tunnels" | ./jq -r '.tunnels[] | select(.proto=="https") | .public_url')

        if [ -z "$ACAPY_WSENDPOINT" ] || [ "$ACAPY_WSENDPOINT" = "null" ]; then
            echo "ngrok not ready, sleeping 5 seconds...."
            sleep 5
        fi
    done

    echo "fetched end point [$ACAPY_ENDPOINT]"
    echo "fetched ws end point [$ACAPY_WSENDPOINT]"
    ACAPY_ENDPOINT="[$ACAPY_ENDPOINT, ${ACAPY_WSENDPOINT/http/ws}]" 
    export ACAPY_ENDPOINT="$ACAPY_ENDPOINT"

elif [[ "${ENV}" == "local_tunnel" ]]; then
    TUNNEL_ENDPOINT=${TUNNEL_ENDPOINT:-http://tunnel:4040}

    while [[ "$(curl -s -o /dev/null -w '%{http_code}' "${TUNNEL_ENDPOINT}/status")" != "200" ]]; do
        echo "Waiting for tunnel..."
        sleep 1
    done
    ACAPY_ENDPOINT=$(curl --silent "${TUNNEL_ENDPOINT}/start" | python -c "import sys, json; print(json.load(sys.stdin)['url'])")
    echo "fetched end point [$ACAPY_ENDPOINT]"


    TUNNEL_WS_ENDPOINT=${TUNNEL_WS_ENDPOINT:-http://tunnel_ws:4040}

    while [[ "$(curl -s -o /dev/null -w '%{http_code}' "${TUNNEL_WS_ENDPOINT}/status")" != "200" ]]; do
        echo "Waiting for tunnel..."
        sleep 1
    done
    ACAPY_WSENDPOINT=$(curl --silent "${TUNNEL_WS_ENDPOINT}/start" | python -c "import sys, json; print(json.load(sys.stdin)['url'])")
    echo "fetched ws end point [$ACAPY_WSENDPOINT]"

    ACAPY_ENDPOINT="[$ACAPY_ENDPOINT, ${ACAPY_WSENDPOINT/http/ws}]"
    export ACAPY_ENDPOINT="$ACAPY_ENDPOINT"

else
    export ACAPY_ENDPOINT="[http://$MEDIATOR_AGENT_HOST:8000, ws://$MEDIATOR_AGENT_HOST:8010]"
fi

echo "Starting aca-py agent with endpoint [$ACAPY_ENDPOINT] ... with config ${MEDIATOR_ARG_FILE}"

export POSTGRESQL_URL="${POSTGRESQL_HOST}:${POSTGRESQL_PORT}"
exec aca-py start --auto-provision \
    --no-ledger \
    --open-mediation \
    --enable-undelivered-queue \
    --debug-connections \
    --connections-invite \
    --invite-label "${MEDIATOR_AGENT_LABEL}" \
    --invite-multi-use \
    --auto-accept-invites \
    --auto-accept-requests \
    --auto-ping-connection \
    --label "${MEDIATOR_AGENT_LABEL}" \
    --inbound-transport http 0.0.0.0 8000 \
    --inbound-transport ws 0.0.0.0 8010 \
    --outbound-transport ws \
    --outbound-transport http \
    --wallet-name "${MEDIATOR_WALLET_NAME}"
    --wallet-key "${MEDIATOR_WALLET_KEY}"
    --wallet-type indy \
    --wallet-storage-type postgres_storage \
    --wallet-storage-config '{"url":${POSTGRESQL_URL},"max_connections":5}' \
    --wallet-storage-creds '{"account":${POSTGRESQL_USER},"password":${POSTGRESQL_PASSWORD},"admin_account":${POSTGRESQL_ADMIN_USER},"admin_password":${POSTGRESQL_ADMIN_PASSWORD}}' \
    --admin 0.0.0.0 ${MEDIATOR_AGENT_HTTP_ADMIN_PORT} \
    --${MEDIATOR_AGENT_ADMIN_MODE} \
    ${MEDIATOR_CONTROLLER_WEBHOOK}



