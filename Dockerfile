FROM alpine:edge

ENV SUMO_VERSION 0_32_0
ENV XERCES_VERSION 3.2.1
ENV PROJ_VERSION 5.1.0
ENV SUMO_HOME /opt/sumo

# from https://github.com/docker-library/python/blob/7a794688c7246e7eff898f5288716a3e7dc08484/3.7/alpine3.8/Dockerfile
ENV GPG_KEY 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
ENV PYTHON_VERSION 3.7.0

RUN set -ex \
	&& apk add --no-cache --virtual .fetch-deps \
		gnupg \
		libressl \
		tar \
		xz \
	\
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
	&& gpg --batch --verify python.tar.xz.asc python.tar.xz \
	&& { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
	&& rm -rf "$GNUPGHOME" python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	\
	&& apk add --no-cache --virtual .build-deps  \
		bzip2-dev \
		coreutils \
		dpkg-dev dpkg \
		expat-dev \
		findutils \
		gcc \
		gdbm-dev \
		libc-dev \
		libffi-dev \
		libnsl-dev \
		libressl \
		libressl-dev \
		libtirpc-dev \
		linux-headers \
		make \
		ncurses-dev \
		pax-utils \
		readline-dev \
		sqlite-dev \
		tcl-dev \
		tk \
		tk-dev \
		xz-dev \
		zlib-dev \
# add build deps before removing fetch deps in case there's overlap
	&& apk del .fetch-deps \
	\
	&& cd /usr/src/python \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--without-ensurepip \
	&& make -j "$(nproc)" \
# set thread stack size to 1MB so we don't segfault before we hit sys.getrecursionlimit()
# https://github.com/alpinelinux/aports/commit/2026e1259422d4e0cf92391ca2d3844356c649d0
		EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000" \
	&& make install \
	\
	&& find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec scanelf --needed --nobanner --format '%n#p' '{}' ';' \
		| tr ',' '\n' \
		| sort -u \
		| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
		| xargs -rt apk add --virtual .python-rundeps \
	&& apk del .build-deps \
	\
	&& find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + \
	&& rm -rf /usr/src/python \
	\
	&& python3 --version

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
	&& ln -s idle3 idle \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 10.0.1

RUN set -ex; \
	\
	apk add --no-cache --virtual .fetch-deps libressl; \
	\
	wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
	\
	apk del .fetch-deps; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip --version; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

# Install dependencies
RUN apk -X http://dl-cdn.alpinelinux.org/alpine/edge/testing --update --no-cache add \
     build-base \	
     libtool \
     autoconf \
     openssh-client \
     git \
     gdal \
     automake


# Install not packaged dependencies
WORKDIR /tmp
RUN wget -t 3 http://www-us.apache.org/dist/xerces/c/3/sources/xerces-c-$XERCES_VERSION.tar.xz -O /tmp/xerces-c-$XERCES_VERSION.tar.xz &&\
	tar xvJpf xerces-c-$XERCES_VERSION.tar.xz &&\
	cd xerces-c-$XERCES_VERSION &&\
	./configure &&\
	make -j$(nproc) &&\
	make install clean &&\
	cd .. &&\
	rm -rf xerces-c-$XERCES_VERSION*

RUN wget -t 3 http://download.osgeo.org/proj/proj-$PROJ_VERSION.tar.gz -O /tmp/proj-$PROJ_VERSION.tar.gz &&\
	tar xvzpf proj-$PROJ_VERSION.tar.gz &&\
	cd proj-$PROJ_VERSION &&\
	./configure &&\
	make -j$(nproc) &&\
	make install clean &&\
	cd .. &&\
	rm -rf proj-$PROJ_VERSION*

# Download and extract SUMO source code
RUN wget -t 3 https://github.com/DLR-TS/sumo/archive/v$SUMO_VERSION.tar.gz -O /tmp/$SUMO_VERSION.tar.gz &&\
mkdir -p $SUMO_HOME &&\
tar xzf /tmp/$SUMO_VERSION.tar.gz -C /opt/sumo --strip 1 &&\
rm /tmp/$SUMO_VERSION.tar.gz

# Configure and build from source.
# Ensure the installation works. If this call fails, the whole build will fail.
WORKDIR $SUMO_HOME
RUN make -f Makefile.cvs &&\
./configure &&\
make -j$(nproc) &&\
make install clean &&\
sumo

# Add volume to allow for host data to be used
RUN mkdir ~/data
VOLUME ~/data

# Expose a port so that SUMO can be started with --remote-port 1234 to be controlled from outside Docker
EXPOSE 1234

ENTRYPOINT ["sumo"]

CMD ["--help"]
