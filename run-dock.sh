export MEDIATOR_AGENT_HTTP_IN_PORT=8000
export MEDIATOR_AGENT_WS_IN_PORT=8010

# NOTE: .env file must be created and populated
# see dock/env.example for a template
docker run -it --rm --env-file dock/.env-test \
-p${MEDIATOR_AGENT_HTTP_IN_PORT}:${MEDIATOR_AGENT_HTTP_IN_PORT} \
-p${MEDIATOR_AGENT_WS_IN_PORT}:${MEDIATOR_AGENT_WS_IN_PORT} \
--name dock-mediator dock-mediator:latest