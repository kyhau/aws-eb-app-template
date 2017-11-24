FROM python:3.6

ENV PIP_INDEX_URL $PIP_INDEX_URL

ENV AWS_ACCESS_KEY_ID $AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY $AWS_SECRET_ACCESS_KEY

ADD  .  /opt/apps/sample_service
WORKDIR /opt/apps/sample_service

RUN ((cd /opt/apps/sample_service && pip --no-cache-dir install -e .) && \
     rm -rf /root/.cache/pip)

EXPOSE 8080

#CMD pserve $CONFIG_FILE --reload