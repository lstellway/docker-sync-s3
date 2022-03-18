ARG ALPINE_VERSION=3.15.0
FROM alpine:${ALPINE_VERSION}

# Environment variables
# This script utilizes the AWS command-line interface program
# As a result, this program supports related environment variables:
# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
ENV AWS_ACCESS_KEY_ID_FILE= \
    AWS_SECRET_ACCESS_KEY_FILE= \
    FORCE_INITIAL_RESTORE="false" \
    BACKUP_INTERVAL=42 \
    S3_ENDPOINT_URL= \
    S3_SYNC_RESTORE_FLAGS= \
    S3_SYNC_BACKUP_FLAGS=

COPY entrypoint.sh /entrypoint.sh
RUN apk --update add --no-cache aws-cli \
    && chmod +x /entrypoint.sh

VOLUME /data
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/data" ]

# 5s * 180 retries = 15 minutes
# HEALTHCHECK --interval=5s --retries=180 CMD [ "stat", "/tmp/running" ]
