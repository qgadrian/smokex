#!/bin/bash

if [ $ENABLE_DATADOG_AGENT == 'true' ]; then
  datadog-agent run & \
  /opt/datadog-agent/embedded/bin/trace-agent & \
  /opt/datadog-agent/embedded/bin/process-agent &
fi

exec "$@"
