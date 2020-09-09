#
# The following Docker file provides an image with a release application in a
# production ready environment.
#
# We are using a Ubuntu base image (elixir:X.XX-slim) in the `deploy` image
# because Datadog [only provides
# information](https://docs.datadoghq.com/agent/basic_agent_usage/heroku/#using-heroku-with-docker-images)
# to create an image using this system.
#
# Because of the `deploy` image uses and the Erlang binaries are generated
# using the `build` image, the `build` image used to build a release of the
# application needs to be Ubuntu based as well.
#

###################################
########## BUILD IMAGE ############
###################################

FROM elixir:1.10-slim AS build

# install build dependencies

# uncomment to build with `elixir:1.10-alpine`
#RUN apk add --no-cache build-base npm git python
#RUN apk add --no-cache gmp ncurses-libs

RUN apt-get -qq update
RUN apt-get -qqy install \
  git \
  curl \
  build-essential \
  libssl1.1 \
  libssl-dev \
  inotify-tools

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs

# prepare build dir
WORKDIR /tmp

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY apps/smokex_web/mix.exs ./apps/smokex_web/
COPY apps/smokex/mix.exs ./apps/smokex/
COPY apps/smokex_client/mix.exs ./apps/smokex_client/
COPY config config
RUN mix do deps.get, deps.compile

# build assets
COPY ./apps/smokex_web/priv/ ./apps/smokex_web/priv/
COPY ./apps/smokex_web/assets/ ./apps/smokex_web/assets/

RUN npm install --prefix=./apps/smokex_web/assets --progress=false --no-audit --loglevel=error
RUN npm run --prefix=./apps/smokex_web/assets deploy

RUN mix phx.digest

COPY apps apps

RUN mix compile
RUN mix release smokex

###################################
####### DEPLOYMENT IMAGE ##########
###################################

FROM elixir:1.10-slim as deploy
#FROM datadog/agent:7 as deploy

########## DATADOG AGENT ####################
# Install GPG dependencies
RUN apt-get update \
 && apt-get install -y gpg apt-transport-https gpg-agent curl ca-certificates

# Add Datadog repository and signing key
RUN sh -c "echo 'deb https://apt.datadoghq.com/ stable 7' > /etc/apt/sources.list.d/datadog.list"
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 A2923DFF56EDA6E76E55E492D3A80E30382E94DE

# Install the Datadog agent
RUN apt-get update && apt-get -y --force-yes install --reinstall datadog-agent

# Expose DogStatsD and trace-agent ports
EXPOSE 8125/udp 8126/tcp

# Copy your Datadog configuration
COPY datadog-config/ /etc/datadog-agent/
########## DATADOG AGENT ####################

WORKDIR /app

COPY --from=build /tmp/_build/prod/rel/smokex/ ./
COPY ./docker-entrypoint.sh /

EXPOSE 4000

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["./bin/smokex", "start"]
