FROM docker:1.12

# setup
RUN apk add --update automake libtool m4 autoconf alpine-sdk linux-headers && \
    wget -qO- https://github.com/gmkurtzer/singularity/archive/2.1.2.tar.gz | tar zxv && \
    cd singularity-2.1.2 && ./autogen.sh && ./configure --prefix=/usr/local && make &&  make install && \
    cd ../ && rm -rf singularity-2.1.2 && \
    apk del automake libtool m4 autoconf alpine-sdk linux-headers
RUN mkdir -p /usr/local/var/singularity/mnt
RUN apk add e2fsprogs bash tar rsync python py-pip sudo
ADD requirements.txt /requirements.txt
RUN pip install -r /requirements.txt
ADD setup.sh /setup.sh

# user
ARG user="root"
ARG uid=0
ARG gid=0
ARG group="root"
RUN if ! [ "$user" == "root" ]; then bash /setup.sh; fi
USER $user

# add supplementary scripts
ADD d2s-varscript.py /d2s-varscript.py
ADD docker2singularity.sh /docker2singularity.sh
ADD move-image.sh /move-image.sh
ADD cleanup.sh /cleanup.sh
ADD agavepy/ /agavepy/

CMD ["python", "/d2s-varscript.py"]
