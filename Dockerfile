FROM lambci/lambda:build-nodejs10.x

# general build stuff
RUN yum update -y \
	&& yum groupinstall -y "Development Tools" \
	&& yum install -y wget tar nano

# libvips needs libwebp 0.5 or later and the one on amazonlinux2 is 0.3.0, so
# we have to build it ourselves

# packages needed by libwebp
RUN yum install -y \
	libjpeg-devel \
	libpng-devel \
	libtiff-devel \
	giflib-devel \ 
	libexif-devel

# stuff we need to build our own libvips ... this is a pretty basic selection
# of dependencies, you'll want to adjust these
RUN yum install -y \
	libpng-devel \
	glib2-devel \
	libjpeg-devel \
	libjpeg-turbo-devel \
	expat-devel \
	zlib-devel

# non-standard stuff we build from source goes here
# ENV VIPSHOME /usr/local/vips
ENV VIPSHOME /opt
ENV PKG_CONFIG_PATH $VIPSHOME/lib/pkgconfig


ARG WEBP_VERSION=1.0.2
ARG WEBP_URL=https://storage.googleapis.com/downloads.webmproject.org/releases/webp

RUN cd /usr/local/src \
	&& wget ${WEBP_URL}/libwebp-${WEBP_VERSION}.tar.gz \
	&& tar xzf libwebp-${WEBP_VERSION}.tar.gz \
	&& cd libwebp-${WEBP_VERSION} \
	&& ./configure --enable-libwebpmux --enable-libwebpdemux \
	--prefix=$VIPSHOME \
	&& make V=0 \
	&& make install

ARG LIBDE265_VERSION=1.0.3
ARG LIBDE265_URL=https://github.com/strukturag/libde265/releases/download/v${LIBDE265_VERSION}

RUN cd /usr/local/src \
	&& wget ${LIBDE265_URL}/libde265-${LIBDE265_VERSION}.tar.gz \
	&& tar xzf libde265-${LIBDE265_VERSION}.tar.gz \
	&& cd libde265-${LIBDE265_VERSION} \
	&& ./configure --disable-dec265 --disable-sherlock265 \
	--prefix=$VIPSHOME \
	&& make V=0 \
	&& make install

ARG LIBHEIF_VERSION=1.3.2
ARG LIBHEIF_URL=https://github.com/strukturag/libheif/releases/download/v${LIBHEIF_VERSION}

RUN cd /usr/local/src \
	&& wget ${LIBHEIF_URL}/libheif-${LIBHEIF_VERSION}.tar.gz \
	&& tar xzf libheif-${LIBHEIF_VERSION}.tar.gz \
	&& cd libheif-${LIBHEIF_VERSION} \
	&& ./configure \
	--prefix=$VIPSHOME \
	&& make \
	&& make install

ARG VIPS_VERSION=8.8.3
ARG VIPS_URL=https://github.com/libvips/libvips/releases/download

RUN cd /usr/local/src \
	&& wget ${VIPS_URL}/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.gz \
	&& tar xzf vips-${VIPS_VERSION}.tar.gz \
	&& cd vips-${VIPS_VERSION} \
	&& ./configure --prefix=$VIPSHOME \
	&& make \
	&& make install 

WORKDIR /etc/ld.so.conf.d
RUN echo "/opt/lib" >> libvips.conf && ldconfig -v

WORKDIR /var/task

# RUN mkdir -p nodejs && cd nodejs && LD_LIBRARY_PATH=$VIPSHOME/lib npm install sharp --production --no-package-lock
# RUN ldd nodejs/node_modules/sharp/build/Release/sharp.node

RUN mkdir -p lib
WORKDIR /var/task/lib

RUN cp -a $VIPSHOME/lib/*.so* . && \
	cp /usr/lib64/libgobject-2.0.so.0 . && \
	cp /usr/lib64/libglib-2.0.so.0 . && \
	cp /usr/lib64/libstdc++.so.6 . && \
	cp /usr/lib64/libm.so.6 . && \
	cp /usr/lib64/libgcc_s.so.1 . && \
	cp /usr/lib64/libpthread.so.0 . && \
	cp /usr/lib64/libc.so.6 . && \
	cp /usr/lib64/libz.so.1 . && \
	cp /usr/lib64/libgif.so.4 . && \
	cp /usr/lib64/libpng15.so.15 . && \
	cp /usr/lib64/libtiff.so.5 . && \
	cp /usr/lib64/libjpeg.so.62 . && \
	cp /usr/lib64/libgmodule-2.0.so.0 . && \
	cp /usr/lib64/libexpat.so.1 . && \
	cp /usr/lib64/libexif.so.12 . && \
	cp /usr/lib64/libpcre.so.1 .&& \
	cp /usr/lib64/libffi.so.6 . && \
	cp /usr/lib64/libjbig.so.2.0 . && \
	cp /usr/lib64/libdl.so.2 . && \
	cp /usr/lib64/libICE.so.6 . && \
	cp /usr/lib64/libSM.so.6 . && \
	cp /usr/lib64/libuuid.so.1 . && \
	cp /usr/lib64/libxcb.so.1 . && \
	cp /usr/lib64/libXau.so.6 . && \
	cp /usr/lib64/libX11.so.6 .
# cp /usr/lib64/*.so* .

WORKDIR /var/task

# # RUN mkdir -p lib && cd lib/ \
# # 	cp -a $VIPSHOME/lib/*.so* . && \
# # 	ln -s /lib64/libgobject-2.0.so.0 libgobject-2.0.so.0 && \
# # 	ln -s /lib64/libglib-2.0.so.0 libglib-2.0.so.0 && \
# # 	ln -s /lib64/libstdc++.so.6 libstdc++.so.6 && \
# # 	ln -s /lib64/libm.so.6 libm.so.6 && \
# # 	ln -s /lib64/libgcc_s.so.1 libgcc_s.so.1 && \
# # 	ln -s /lib64/libpthread.so.0 libpthread.so.0 && \
# # 	ln -s /lib64/libc.so.6 libc.so.6 && \
# # 	ln -s /lib64/libz.so.1 libz.so.1 && \
# # 	ln -s /lib64/libpng15.so.15 libpng15.so.15 && \
# # 	ln -s /lib64/libtiff.so.5 libtiff.so.5 && \
# # 	ln -s /lib64/libjpeg.so.62 libjpeg.so.62 && \
# # 	ln -s /lib64/libgmodule-2.0.so.0 libgmodule-2.0.so.0 && \
# # 	ln -s /lib64/libexpat.so.1 libexpat.so.1 && \
# # 	ln -s /lib64/libexif.so.12 libexif.so.12 && \
# # 	ln -s /lib64/libpcre.so.1 libpcre.so.1 && \
# # 	ln -s /lib64/libffi.so.6 libffi.so.6 && \
# # 	ln -s /lib64/libjbig.so.2.0 libjbig.so.2.0 && \
# # 	ln -s /lib64/libdl.so.2 libdl.so.2