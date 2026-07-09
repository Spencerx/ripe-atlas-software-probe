#!/usr/bin/env bash
# Create users
useradd ripe-atlas
useradd ripe-atlas-measurement

# Build/Install
autoreconf -iv
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --libdir=/usr/lib64 --runstatedir=/run --with-user=ripe-atlas --with-group=ripe-atlas --with-measurement-user=ripe-atlas-measurement --disable-systemd --enable-chown --enable-setcap-install
make
make install
