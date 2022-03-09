export MEDIATOR_AGENT_HTTP_IN_PORT=8000
export MEDIATOR_AGENT_WS_IN_PORT=8010
export MEDIATOR_ENV_FILE=dock/.env-test

# NOTE: .env file must be created and populated
# see dock/env.example for a template
if [ ! -f "${MEDIATOR_ENV_FILE}" ]; then
  echo "Env file ${MEDIATOR_ENV_FILE} not found."
  exit 1
fi

docker run -it --rm \
--env-file ${MEDIATOR_ENV_FILE} \
-p${MEDIATOR_AGENT_HTTP_IN_PORT}:${MEDIATOR_AGENT_HTTP_IN_PORT} \
-p${MEDIATOR_AGENT_WS_IN_PORT}:${MEDIATOR_AGENT_WS_IN_PORT} \
--name dock-mediator dock-mediator:latest