FROM python:alpine3.6

COPY ./* /root/
RUN apk update && \
	apk add make --virtual .build-deps && \
    cd /root && make install && \
    apk del make --purge .build-deps

ENV BROWSER=
ENTRYPOINT ["googler"]
