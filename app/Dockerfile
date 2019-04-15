FROM python:3.6
LABEL maintainer="virtualda@gmail.com"

ENV PIP_INDEX_URL $PIP_INDEX_URL

ADD  .  /opt/apps/sample_service
WORKDIR /opt/apps/sample_service

RUN ((cd /opt/apps/sample_service && pip --no-cache-dir install -e .) && \
     rm -rf /root/.cache/pip)

EXPOSE 8080

#CMD pserve $CONFIG_FILE --reload