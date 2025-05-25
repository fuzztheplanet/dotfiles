#!/bin/sh

RS_CMD='redshift -m randr -l 49.62:6.14'
[ -n "$(ps aux |grep -v grep | grep redshift)" ] && killall redshift || $RS_CMD
