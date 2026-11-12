# Cron container: runs download_tiles.sh on schedule, driving the host Docker (planetiler run + Martin restart)
FROM docker:27.5.1-cli

RUN apk add --no-cache bash tzdata

# Install supercronic (cron for containers: job output goes to the container logs)
ARG SUPERCRONIC_VERSION=v0.2.49
ARG SUPERCRONIC_SHA256=a53ae236602c7338aba3fbaff40bda6300eae3b9fedb8261eb06cfe3724430c1
RUN wget -q -O /usr/local/bin/supercronic \
    https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-linux-amd64 \
    && echo "${SUPERCRONIC_SHA256}  /usr/local/bin/supercronic" | sha256sum -c - \
    && chmod +x /usr/local/bin/supercronic

# Relative to working_dir (the project dir, set in compose)
CMD ["supercronic", "-inotify", "planetiler/crontab"]
