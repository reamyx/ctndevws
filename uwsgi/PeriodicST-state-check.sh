#!/bin/env sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" 
cd "$(dirname "$0")"

#服务状态测试
pidof "uwsgi" &> "/dev/null"
