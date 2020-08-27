#
# Generate static files
#
FROM elixir:1.10-alpine as asset-builder

RUN apk update \
 && apk add --no-cache gmp ncurses-libs

RUN apk add build-base nodejs npm yarn python

RUN mkdir /app
WORKDIR /app

COPY ./ ./

RUN cd ./apps/smokex_web/assets \
  && npm install \
  && npm run deploy

#
# Compiler image
#

FROM elixir:1.10-slim as builder

WORKDIR /app

ARG MIX_ENV=prod

RUN \
  mix local.hex --force \
  && mix local.rebar --force \
  && mix hex.info

COPY config ./
COPY deps ./
COPY mix.exs mix.lock ./

RUN mix deps.get
RUN mix deps.compile

COPY ./ ./

COPY --from=asset-builder /app/apps/smokex_web/priv/static/ ./apps/smokex_web/priv/static/

RUN mix release smokex

#
# Deployment image
#

FROM elixir:1.10-slim

#
########## DATADOG AGENT
#

# Install GPG dependencies
RUN apt-get update \
 && apt-get install -y gpg apt-transport-https gpg-agent curl ca-certificates

# Add Datadog repository and signing key
RUN sh -c "echo 'deb https://apt.datadoghq.com/ stable 7' > /etc/apt/sources.list.d/datadog.list"
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 A2923DFF56EDA6E76E55E492D3A80E30382E94DE

# Install the Datadog agent
RUN apt-get update && apt-get -y --force-yes install --reinstall datadog-agent

# Copy entrypoint
COPY ./docker-entrypoint.sh /

# Expose DogStatsD and trace-agent ports
EXPOSE 8125/udp 8126/tcp

# Copy your Datadog configuration
COPY datadog-config/ /etc/datadog-agent/

##############

ARG MIX_ENV=prod

WORKDIR /app

COPY --from=builder /app/_build/${MIX_ENV}/rel/smokex/ ./

EXPOSE 4000

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["./bin/smokex", "start"]
