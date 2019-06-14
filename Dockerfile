#官方centos7镜像初始化,镜像TAG: ctndevws

FROM        imginit
LABEL       function="ctndevws"

#添加本地资源
ADD     nginx     /srv/nginx/
ADD     uwsgi     /srv/uwsgi/
ADD     devws     /srv/devws/

WORKDIR /srv/devws

#功能软件包
RUN     set -x \
        && cd ../imginit \
        && mkdir -p installtmp \
        && cd installtmp \
        \
        && yum -y install gcc g++ make automake gdb openssl-devel zlib-devel \
                readline-devel curl-devel expat-devel gettext-devel \
                perl-ExtUtils-MakeMaker \
        \
        && yum -y remove git \
        && curl -O https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.22.0.tar.gz \
        && tar -zxvf git-2.22.0.tar.gz \
        && cd git-2.22.0 \
        && ./configure prefix=/usr/local
        && make \
        && make install \
        && cd - \
        \
        && yum -y install nginx httpd-tools fcgi fcgi-devel spawn-fcgi \
        && git clone https://github.com/gnosek/fcgiwrap 
        && cd fcgiwrap \
        && autoreconf -i \
        && ./configure \
        && make \
        && make install \
        && cd - \
        \
        && yum install -y libffi-devel sqlite-devel \
        && curl -O https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz \
        && tar -zxvf Python-3.7.3.tgz \
        && cd Python-3.7.3 \
        && ./configure --enable-shared  --enable-optimizations \
        && make \
        && make install \
        && mkdri -p /etc/ld.so.conf.d \
        && echo "/usr/local/lib" > /etc/ld.so.conf.d/Python3Lib.conf \
        && ldconfig \
        && cd - \
        \
        && pip3 install --upgrade pip \
        && python3 -m venv /srv/PY3N \
        && source /srv/PY3N/bin/activate \
        && pip3 install --upgrade pip gevent \
        && deactivate \
        \
        curl -L -O https://www.lua.org/work/lua-5.4.0-alpha-rc2.tar.gz \
        && tar -zxvf lua-5.4.0-alpha-rc2.tar.gz \
        && cd lua-5.4.0-alpha \
        && make linux \
        && make install \
        && cd - \
        \
        && curl -L -O https://nodejs.org/dist/v12.4.0/node-v12.4.0-linux-x64.tar.xz \
        && xz -d node-v12.4.0-linux-x64.tar.xz \
        && tar -xvf node-v12.4.0-linux-x64.tar \
        && cd node-v12.4.0-linux-x64 \
        && \cp -rf bin include lib share /usr/local \
        && cd - \
        \
        && curl -L -O https://studygolang.com/dl/golang/go1.12.5.linux-amd64.tar.gz \
        && tar -zxvf go1.12.5.linux-amd64.tar.gz \
        && mkdir -p /usr/local/go
        && \cp -rf go/{bin,pkg,src} /usr/local/go \
        && mkdir -p /srv/Gowkdir/src/golang.org/x \
        && git clone https://github.com/golang/tools \
        && rm -rf tools/.git \
        && mv -f tools /srv/Gowkdir/src/golang.org/x \
        && echo "export GOPATH=\"/srv/Gowkdir\"" > /etc/profile.d/GoPathSet.sh
        && echo "export PATH=\"\$PATH:/usr/local/go/bin\"" > /etc/profile.d/GoBinSet.sh
        \
        && git clone https://github.com/unbit/uwsgi \
        && cd uwsgi \
        && make "nolang" UWSGI_BIN_NAME="/usr/local/bin/uwsgi" \
        && make plugin.python  PROFILE="nolang" PYTHON="python3" \
        && make plugin.gevent  PROFILE="nolang" PYTHON="python3" \
        && make plugin.asyncio PROFILE="nolang" PYTHON="python3" \
        && make plugin.lua     PROFILE="nolang" UWSGICONFIG_LUAPC="lua5.4" \
        && make plugin.cgi     PROFILE="nolang" \
        && mv python_plugin.so  python3_plugin.so \ 
        && mkdir -p ../../../uwsgi/uplugins \
        && \cp -f *.so ../../../uwsgi/uplugins \
        && cd - \
        \
        && cd ../ \
        && yum clean all \
        && rm -rf installtmp /tmp/* \
        && find ../ -name "*.sh" -exec chmod +x {} \;

ENV       ZXDK_THIS_IMG_NAME    "ctndevws"
ENV       SRVNAME               "devws"

# ENTRYPOINT CMD
CMD [ "../imginit/initstart.sh" ]
