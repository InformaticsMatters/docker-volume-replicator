FROM debian:12.1-slim

LABEL maintainer="achristie@informaticsmatters.com"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gnupg \
        lsb-release \
        openssh-client \
        rsync \
        s3fs \
        sshpass \
        tzdata \
        wget

# Set the image timezone...
ENV TZ=UTC

COPY docker-entrypoint.sh .
COPY rsync-exclude.txt .

CMD ["./docker-entrypoint.sh"]
