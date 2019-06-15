#!/bin/env sh
exit 0

# dev01,持久化
SRVCFG='{"initdelay":3,
"workstart":"sleep 15",
"workwatch":30,"workintvl":5,
"firewall":{"tcpportpmt":"80:99",
"udpportpmt": "80:90"},
"sshsrv":{"enable":"yes",
"sshport": 24,"rootpwd":"abc000"},
"inetdail":{"enable":"yes",
"dialuser":"a15368400819",
"dialpswd":"a123456",
"usedefgw":"yes"}}'; \
docker stop dev01; docker rm dev01; \
docker container run --detach --restart always \
--name dev01 --hostname dev01 \
--network imvn --cap-add NET_ADMIN \
--sysctl "net.ipv4.ip_forward=1" \
--device /dev/ppp --device /dev/net/tun \
--volume /etc/localtime:/etc/localtime:ro \
--dns 192.168.15.192 --dns-search local \
--env "SRVCFG=$SRVCFG" ctndevws; \
docker network connect emvn dev01

docker container exec -it dev01 bash
