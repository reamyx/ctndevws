#!/bin/env sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"; cd "$(dirname "$0")"
exec 4>&1; ECHO(){ echo "${@}" >&4; }; exec 3<>"/dev/null"; exec 0<&3;exec 1>&3;exec 2>&3

#先行服务停止
for ID in {1..20}; do pkill "^uwsgi$" || break; sleep 0.5; done
[ "$1" == "stop" ] && exit 0

#DDNS注册
DDNSREG="./PeriodicRT-ddns-update"
[ -f "$DDNSREG" ] && ( chmod +x "$DDNSREG"; setsid "$DDNSREG" & )

#环境变量未能提供配置数据时从配置文件读取
[ -z "$SRVCFG" ] && SRVCFG="$( jq -scM ".[0]|objects" "./workcfg.json" )"

SRVPORT="$( echo "$SRVCFG" | jq -r ".uwsgi.srvport|numbers"  )"
SRVPROT="$( echo "$SRVCFG" | jq -r ".uwsgi.protocol|strings" )"
GWTYPE="$( echo "$SRVCFG" | jq -r ".uwsgi.gwtype|strings"    )"
GWFILE="$( echo "$SRVCFG" | jq -r ".uwsgi.gwfile|strings"    )"

#协议检查
SRVPROT="$( echo "http https fastcgi scgi uwsgi suwsgi" | grep -Ewo "$SRVPROT" )"
SRVPROT="${SRVPROT:-uwsgi}"

#网关类型配置
GWTYPE="$( echo "python3 lua cgi" | grep -Ewo "$GWTYPE" )"

[[ "$GWTYPE" == "python3" || -z "$GWTYPE" ]] && {
    SRVPORT="${SRVPORT:-8003}"; GFPM=( "--wsgi-file" "${GWFILE:-wsgi.py}" ); }
    
[ "$GWTYPE" == "lua"     ] && {
    SRVPORT="${SRVPORT:-8005}"; GFPM=( "--lua" "${GWFILE:-wsapi.lua}" ); }
    
[ "$GWTYPE" == "cgi"     ] && {
    SRVPORT="${SRVPORT:-8006}"; GFPM=( "--cgi" "${GWFILE:-./}" ); }

SRVPROT="--$SRVPROT-socket"; SRVPORT=":$SRVPORT"
INI=( "--ini" "uwsgi.ini${GWTYPE:+:$GWTYPE}" )

#配置端口并启动nginx服务
exec uwsgi "$SRVPROT" "$SRVPORT" "${INI[@]}" "${GFPM[@]}"

exit 127
