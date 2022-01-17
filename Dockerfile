FROM debian:bullseye-slim AS builder
ARG GUAC_VER=1.4.0
ARG PREFIX_DIR=/usr/local/guacamole
ARG DEBIAN_FRONTEND=noninteractive
#Add backports
ARG DEBIAN_RELEASE=bullseye-backports
RUN grep " ${DEBIAN_RELEASE} " /etc/apt/sources.list || echo >> /etc/apt/sources.list \
    "deb http://deb.debian.org/debian ${DEBIAN_RELEASE} main contrib non-free"

COPY bin-guacd "${PREFIX_DIR}/bin/"
# Install dependencies
RUN apt-get update && apt-get install -t ${DEBIAN_RELEASE} -y \
    libcairo2-dev libjpeg62-turbo-dev libpng-dev libwebp-dev libgcrypt-dev \
    libossp-uuid-dev libavcodec-dev libavutil-dev \
    libswscale-dev libfreerdp-client2-2 libpango1.0-dev \
    libssh2-1-dev libtelnet-dev libvncserver-dev libavformat-dev \
    libpulse-dev libssl-dev libvorbis-dev libwebp-dev libwebsockets-dev libtool \
    git autoconf automake autotools-dev gcc make freerdp2-dev ghostscript \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /root
# Install guacamole-server & compile hardening
RUN git clone git://github.com/apache/guacamole-server \
  && cd guacamole-server \
  && autoreconf -fi \
  && CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2" CPPFLAGS="-Wdate-time -D_FORTIFY_SOURCE=2" CXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2" FCFLAGS="-g -O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2" FFLAGS="-g -O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2" GCJFLAGS="-g -O2 -fstack-protector-strong" LDFLAGS="-Wl,-z,relro -Wl,-z,now" OBJCFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security" OBJCXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security" ./configure --prefix="${PREFIX_DIR}" --with-freerdp-plugin-dir="${PREFIX_DIR}/lib/freerdp2"\
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && cd .. \
  && rm -rf guacamole-server \
  && ldconfig

RUN ${PREFIX_DIR}/bin/list-dependencies.sh     \
        ${PREFIX_DIR}/sbin/guacd               \
        ${PREFIX_DIR}/bin/guacenc             \
        ${PREFIX_DIR}/bin/guaclog             \
        ${PREFIX_DIR}/lib/libguac-client-*.so  \
        ${PREFIX_DIR}/lib/freerdp2/*guac*.so   \
        > ${PREFIX_DIR}/DEPENDENCIES

FROM debian:bullseye-slim
ARG DEBIAN_RELEASE=bullseye-backports
RUN grep " ${DEBIAN_RELEASE} " /etc/apt/sources.list || echo >> /etc/apt/sources.list \
    "deb http://deb.debian.org/debian ${DEBIAN_RELEASE} main contrib non-free"
ARG PREFIX_DIR=/usr/local/guacamole

ARG RUNTIME_DEPENDENCIES="            \
        netcat-openbsd                \
        ca-certificates               \
        ghostscript                   \
        fonts-liberation              \
        fonts-dejavu                  \
        xfonts-terminus"

# Do not require interaction during build
ARG DEBIAN_FRONTEND=noninteractive

# Copy build artifacts into this stage
COPY --from=builder ${PREFIX_DIR} ${PREFIX_DIR}

RUN apt-get update                                                                                       && \
    apt-get install -t ${DEBIAN_RELEASE} -y --no-install-recommends $RUNTIME_DEPENDENCIES                && \
    apt-get install -t ${DEBIAN_RELEASE} -y --no-install-recommends $(cat "${PREFIX_DIR}"/DEPENDENCIES)  && \
    rm -rf /var/lib/apt/lists/*

# Link FreeRDP plugins into proper path
RUN ${PREFIX_DIR}/bin/link-freerdp-plugins.sh \
        ${PREFIX_DIR}/lib/freerdp2/libguac*.so

# Checks the operating status every 5 minutes with a timeout of 5 seconds
HEALTHCHECK --interval=5m --timeout=5s CMD nc -z 127.0.0.1 4822 || exit 1

# Create a new user guacd
RUN groupadd --gid 1000 guacd
RUN useradd --system --create-home --shell /usr/sbin/nologin --uid 1000 --gid 1000 guacd

ENV GUACD_LOG_LEVEL=info
ENV LD_LIBRARY_PATH=${PREFIX_DIR}/lib
ENV LC_ALL=C.UTF-8

WORKDIR /home/guacd
USER guacd
EXPOSE 4822
CMD /usr/local/guacamole/sbin/guacd -b 0.0.0.0 -L $GUACD_LOG_LEVEL -f
