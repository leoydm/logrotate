FROM alpine:latest
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

# logrotate version (e.g. 3.9.1-r0)
ARG LOGROTATE_VERSION=latest
# permissions
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000
ARG TARGETPLATFORM

# install dev tools
RUN export CONTAINER_USER=logrotate && \
    export CONTAINER_GROUP=logrotate && \
    addgroup -g $CONTAINER_GID logrotate && \
    adduser -u $CONTAINER_UID -G logrotate -h /usr/bin/logrotate.d -s /bin/bash -S logrotate && \
    apk add --update \
      bash \
      tini \
      tar \
      gzip \
      wget \
      tzdata && \
    if  [ "${LOGROTATE_VERSION}" = "latest" ]; \
      then apk add logrotate ; \
      else apk add "logrotate=${LOGROTATE_VERSION}" ; \
    fi && \
    mkdir -p /usr/bin/logrotate.d && \
    if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      wget --no-check-certificate -O /tmp/go-cron-amd64.tar.gz https://github.com/leoydm/go-cron/releases/download/v1/go-cron-amd64.tar.gz && \
      tar xvf /tmp/go-cron-amd64.tar.gz -C /usr/bin ; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      wget --no-check-certificate -O /tmp/go-cron-arm64.tar.gz https://github.com/leoydm/go-cron/releases/download/v1/go-cron-arm64.tar.gz && \
      tar xvf /tmp/go-cron-arm64.tar.gz -C /usr/bin ; \
    fi && \
    apk del \
      wget && \
    rm -rf /var/cache/apk/* && rm -rf /tmp/*

# environment variable for this container
ENV LOGROTATE_OLDDIR= \
    LOGROTATE_COMPRESSION= \
    LOGROTATE_INTERVAL= \
    LOGROTATE_COPIES= \
    LOGROTATE_SIZE= \
    LOGS_DIRECTORIES= \
    LOG_FILE_ENDINGS= \
    LOGROTATE_LOGFILE= \
    LOGROTATE_CRONSCHEDULE= \
    LOGROTATE_PARAMETERS= \
    LOGROTATE_STATUSFILE= \
    LOG_FILE=

COPY docker-entrypoint.sh /usr/bin/logrotate.d/docker-entrypoint.sh
COPY update-logrotate.sh /usr/bin/logrotate.d/update-logrotate.sh
COPY logrotate.sh /usr/bin/logrotate.d/logrotate.sh
COPY logrotateConf.sh /usr/bin/logrotate.d/logrotateConf.sh
COPY logrotateCreateConf.sh /usr/bin/logrotate.d/logrotateCreateConf.sh

ENTRYPOINT ["/sbin/tini","--","/usr/bin/logrotate.d/docker-entrypoint.sh"]
#ENTRYPOINT ["sleep"]
VOLUME ["/logrotate-status"]
CMD ["cron"]
#CMD ["100000"]
