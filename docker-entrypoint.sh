#!/bin/bash

datadog-agent run & \
/opt/datadog-agent/embedded/bin/trace-agent & \
/opt/datadog-agent/embedded/bin/process-agent &

exec "$@"
