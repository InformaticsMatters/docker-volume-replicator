FROM alpine:3.15.0

LABEL maintainer="achristie@informaticsmatters.com"

RUN apk update && \
    apk add rsync openssh

COPY docker-entrypoint.sh .
COPY rsync-exclude.txt .

CMD ["./docker-entrypoint.sh"]
