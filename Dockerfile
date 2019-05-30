#官方centos7镜像初始化,镜像TAG: ctnwebgw

FROM        imginit
LABEL       function="ctnwebgw"

#添加本地资源
ADD     nginx     /srv/nginx/
ADD     uwsgi     /srv/uwsgi/

WORKDIR /srv/nginx

#功能软件包
RUN     set -x \
        && cd ../imginit \
        && mkdir -p installtmp \
        && cd installtmp \
        \
        && yum -y install nginx httpd-tools fcgi spawn-fcgi python2-pip \
                          python36 \
        && yum -y install gcc make automake fcgi-devel zlib-devel openssl-devel \
                          python-devel python36-devel readline-devel \
        \
        && curl https://codeload.github.com/gnosek/fcgiwrap/zip/master -o fcgiwrap.zip \
        && unzip fcgiwrap.zip \
        && cd fcgiwrap-master \
        && autoreconf -i \
        && ./configure \
        && make \
        && make install \
        && cd - \
        \
        && pip install --upgrade pip virtualenv \
        && virtualenv -p python36 /srv/ENVPY3 \
        && source /srv/ENVPY3/bin/activate \
        && pip install gevent \
        && deactivate \
        \
        && curl -L -O http://www.lua.org/ftp/lua-5.3.5.tar.gz \
        && tar -zxvf lua-5.3.5.tar.gz \
        && cd lua-5.3.5 \
        && make linux \
        && make install \
        && cd - \
        \
        && curl -L -O http://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz \
        && tar -zxvf LuaJIT-2.1.0-beta3.tar.gz \
        && cd LuaJIT-2.1.0-beta3 \
        && make \
        && make install \
        && ln -sf ./luajit-2.1.0-beta3 /usr/local/bin/luajit \
        && cd - \
        \
        && curl https://codeload.github.com/unbit/uwsgi/zip/master -o uwsgi.zip \
        && unzip uwsgi.zip \
        && cd uwsgi-master \
        && UWSGI_PROFILE="nolang" UWSGI_BIN_NAME="/usr/local/bin/uwsgi" make \
        && PYTHON=python36 uwsgi --build-plugin "plugins/python python3" \
        && PYTHON=python36 uwsgi --build-plugin "plugins/gevent geventpy3" \
        &&                 uwsgi --build-plugin "plugins/asyncio asyncio" \
        && UWSGICONFIG_LUAPC=lua uwsgi --build-plugin "plugins/lua lua" \
        && UWSGICONFIG_LUAPC=luajit uwsgi --build-plugin "plugins/lua luajit" \
        && uwsgi --build-plugin "plugins/cgi cgi" \
        && mkdir -p ../../../uwsgi/uplugins \
        && \cp -f *.so ../../../uwsgi/uplugins \
        && cd - \
        \
        && cd ../ \
        && yum -y history undo last \
        && yum clean all \
        && rm -rf installtmp /tmp/* \
        && find ../ -name "*.sh" -exec chmod +x {} \;

ENV       ZXDK_THIS_IMG_NAME    "ctnwebgw"
ENV       SRVNAME               "nginx"

# ENTRYPOINT CMD
CMD [ "../imginit/initstart.sh" ]
