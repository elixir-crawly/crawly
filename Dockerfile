# ===================== base =====================
FROM elixir:alpine as build

# install build dependencies
RUN apk add --update git make gcc libc-dev autoconf libtool automake

# set build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=standalone_crawly

# install mix dependencies
COPY mix.exs mix.lock /app/
COPY priv /app/priv/
COPY rel /app/rel



RUN mix deps.get
RUN mix local.rebar --force
RUN mix deps.compile
RUN mix deps.compile

# build project code
COPY config/config.exs config/
COPY config/crawly.config config/
COPY config/standalone_crawly.exs config/

# Create default config file
# COPY config/app.config /app/config/app.config

# COPY config/runtime.exs config/
COPY lib lib

RUN mix compile

COPY rel rel

## build release
RUN mix release

# =================== release ====================
FROM alpine:latest AS release

RUN apk add --update openssl make gcc libc-dev autoconf libtool automake

WORKDIR /app

RUN apk add --update bash
COPY --from=build /app/_build/standalone_crawly/rel/crawly ./
COPY --from=build /app/config /app/config

RUN mkdir /app/spiders

EXPOSE 4001

ENTRYPOINT [ "/app/bin/crawly", "start" ]
