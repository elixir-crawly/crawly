#!/usr/bin/env bash

set -x
## Setup hex user
mkdir -p ~/.hex
echo '{api_key, <<"'${API_KEY}'">>}.' > ~/.hex/hex.config

MIX_ENV=dev mix deps.get

MIX_ENV=dev mix generate_documentation
MIX_ENV=dev mix hex.publish package --yes
MIX_ENV=dev mix hex.publish docs --yes
MIX_ENV=dev mix clean
MIX_ENV=dev mix deps.clean --all
