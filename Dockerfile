FROM alpine:edge

ENV SUMO_VERSION 0_32_0
ENV XERCES_VERSION 3.2.1
ENV PROJ_VERSION 5.0.0
ENV SUMO_HOME /opt/sumo

# Install dependencies
RUN apk -X http://dl-cdn.alpinelinux.org/alpine/edge/testing --update --no-cache add \
     python \
     python-dev \
     py-pip \
     build-base \	
     python3 \
     py3-pip \
     libtool \
     autoconf \
     openssh-client \
     git \
     gdal \
     automake

# Install not packaged dependencies
WORKDIR /tmp
RUN wget http://www-us.apache.org/dist/xerces/c/3/sources/xerces-c-$XERCES_VERSION.tar.xz -O /tmp/xerces-c-$XERCES_VERSION.tar.xz &&\
	tar xvJpf xerces-c-$XERCES_VERSION.tar.xz &&\
	cd xerces-c-$XERCES_VERSION &&\
	./configure &&\
	make -j$(nproc) &&\
	make install clean &&\
	cd .. &&\
	rm -rf xerces-c-$XERCES_VERSION*

RUN wget http://download.osgeo.org/proj/proj-$PROJ_VERSION.tar.gz -O /tmp/proj-$PROJ_VERSION.tar.gz &&\
	tar xvzpf proj-$PROJ_VERSION.tar.gz &&\
	cd proj-$PROJ_VERSION &&\
	./configure &&\
	make -j$(nproc) &&\
	make install clean &&\
	cd .. &&\
	rm -rf proj-$PROJ_VERSION*

# Download and extract SUMO source code
RUN wget https://github.com/DLR-TS/sumo/archive/v$SUMO_VERSION.tar.gz -O /tmp/$SUMO_VERSION.tar.gz &&\
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
