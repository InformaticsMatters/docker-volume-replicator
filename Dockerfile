FROM debian:12.1-slim

LABEL maintainer="achristie@informaticsmatters.com"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gnupg \
        lsb-release \
        openssh-client \
        rclone \
        rsync \
        s3fs \
        sshpass \
        tzdata \
        wget

# Set the image timezone...
ENV TZ=UTC

COPY docker-entrypoint.sh .
COPY rsync-exclude.txt .
COPY rclone.conf /root/.config/rclone/rclone.conf

RUN chmod 755 /root/.config/rclone/rclone.conf

CMD ["./docker-entrypoint.sh"]
