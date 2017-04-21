FROM python:3-alpine

RUN apk update && \
    apk add ca-certificates wget  && \
    update-ca-certificates

RUN wget https://raw.githubusercontent.com/jarun/googler/v3.0/googler -O /usr/local/bin/googler && \
    chmod +x /usr/local/bin/googler

ENTRYPOINT ["googler"]
