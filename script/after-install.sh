#!/bin/sh

install -d -o graphite -g graphite -m 0750 \
    /opt/graphite/storage \
    /opt/graphite/storage/log \
    /opt/graphite/storage/log/webapp

cd /opt/graphite/service/graphite-web
su graphite -c './manage syncdb --noinput'
