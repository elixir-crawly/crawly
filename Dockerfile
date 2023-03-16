# ===================== base =====================
FROM elixir:alpine as build

# install build dependencies
RUN apk add --update git openssh-client make gcc libc-dev gmp-dev autoconf libtool automake libevent-dev sqlite

# set build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

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
COPY config/prod.exs config/
COPY config/app.config /app/config/app.config

# COPY config/runtime.exs config/
COPY lib lib

RUN mix compile

# COPY rel rel

## build release
RUN mix release

# =================== release ====================
FROM alpine:latest AS release

RUN apk add --update openssl ncurses-libs make gcc libc-dev gmp-dev autoconf libtool automake sqlite openssl1.1-compat

WORKDIR /app

RUN apk add --update bash
COPY --from=build /app/_build/prod/rel/crawly ./
COPY --from=build /app/config /app/config
EXPOSE 4001

# ENTRYPOINT [ "/app/bin/crawly", "start_iex" ]