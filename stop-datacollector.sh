#!/bin/sh
sudo pkill -9 argus
sudo pkill -f argus
sudo pkill -9 nfpcapd
sudo pkill -f nfpcapd
zeekctl stop