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

ARG MIX_ENV=prod

WORKDIR /app

COPY --from=builder /app/_build/${MIX_ENV}/rel/smokex/ ./

EXPOSE 4000

CMD ["start"]
ENTRYPOINT ["./bin/smokex"]

