#!/bin/sh

HOST_IP=$3
HOST_PORT=$4
TIMEOUT_SEC=4

if /usr/bin/expr "$PATH" : '\d*$' >/dev/null; then
  HOST_PORT=$PATH # Allow override using the external-check path option
elif [ -z "$4" -o "$4" = "0" ]; then
  HOST_PORT=17110 # Default to mainnet
  case "$HAPROXY_PROXY_NAME" in
    *test*)
      HOST_PORT=17210 # Assume testnet-10 for backends with test in them
      ;;
    *tn10*)
      HOST_PORT=17210 # Assume testnet-10 for backends with tn10 in them
      ;;
    *tn11*)
      HOST_PORT=17310 # Assume testnet-11 for backends with tn11 in them
      ;;
  esac
fi

${PWD}/kcheck --timeout=${TIMEOUT_SEC}000 ws://$HOST_IP:$HOST_PORT
