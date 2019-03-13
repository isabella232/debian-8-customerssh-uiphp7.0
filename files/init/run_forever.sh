#!/usr/bin/env bash

echo "REMINDER: Stop calling run_forever.sh please."

exec /init/entrypoint /init/supervisord
