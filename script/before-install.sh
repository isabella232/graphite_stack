#!/bin/sh

getent group graphite > /dev/null || \
    addgroup --system graphite > /dev/null

getent passwd graphite > /dev/null || \
    adduser --system --disabled-login --ingroup graphite \
    --home /opt/graphite --gecos 'Graphite' --shell /bin/false \
    graphite > /dev/null
