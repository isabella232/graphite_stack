#!/bin/sh

for d in storage storage/log storage/log/webapp ; do
    test -d /opt/graphite/$d \
        || install -d -o graphite -g graphite -m 0750 /opt/graphite/$d
done

cd /opt/graphite/service/graphite-web
su graphite -s /bin/sh -c './manage syncdb --noinput'
