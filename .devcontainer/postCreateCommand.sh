#!/usr/bin/env bash

set -e

curl -LO https://github.com/williamlsh/http-proxy/releases/download/v0.0.1/http-proxy.amd64

sudo mv http-proxy.amd64 /usr/local/bin/http-proxy
