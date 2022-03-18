#!/bin/sh
# This script utilizes the AWS command-line interface program
# As a result, this program supports related environment variables:
# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html

# Global variables
export ALPHA="${1}"
export BETA="${2}"
export HEALTH_FILE="/tmp/running"

# Fail with message
_fatal() {
    printf "Fatal: %s\n" "$@" >&2 \
    exit 1
}

# Create temporary file to indicate healthy status
_healthy() {
    touch "${HEALTH_FILE}"
}

# Remove health file to indicate unhealthy status
_unhealthy() {
    [ -f "HEALTH_FILE" ] && rm -f "${HEALTH_FILE}"
}

# Check whether a provided directory is empty
# Arguments:
#     1) Path to directory to check
_is_dir_empty() {
    # Check if directory exists and is NOT empty
    [ -d "${1}" ] && [ "$(ls -A "${1}")" ] \
        && return 1 \
        || return 0
}

# Bootstrap using a configuration file
_bootstrap() {
    # Add endpoint
    AWS="aws"
    [ -n "${S3_ENDPOINT_URL}" ] && AWS="aws --endpoint-url ${S3_ENDPOINT_URL}"
    export AWS

    # Get access key id from file
    if [ -r "${AWS_ACCESS_KEY_ID_FILE}" ]; then
        AWS_ACCESS_KEY_ID=$(head -n1 "${AWS_ACCESS_KEY_ID_FILE}")
        export AWS_ACCESS_KEY_ID
    fi

    # Get secret access key from file
    if [ -r "${AWS_SECRET_ACCESS_KEY_FILE}" ]; then
        AWS_SECRET_ACCESS_KEY=$(head -n1 "${AWS_SECRET_ACCESS_KEY_FILE}")
        export AWS_SECRET_ACCESS_KEY
    fi

    # Ensure required variables are set
    [ -z "${ALPHA}" ] && _fatal "'ALPHA' location not set in first entrypoint argument"
    [ -z "${BETA}" ] && _fatal "'BETA' location not set in second entrypoint argument"
}

# Synchronize files from "BETA" > "ALPHA"
_restore() {
    printf "Restoring data from '%s' to '%s'\n" "${BETA}" "${ALPHA}"
    $AWS s3 sync "${BETA}" "${ALPHA}" ${S3_SYNC_RESTORE_FLAGS} \
        && return 0 \
        || return 1
}

# Synchronize files from "ALPHA" to "BETA"
_backup() {
    printf "Backing up data from '%s' to '%s'\n" "${ALPHA}" "${BETA}"
    $AWS s3 sync "${ALPHA}" "${BETA}" ${S3_SYNC_BACKUP_FLAGS} \
        && return 0 \
        || return 1
}

# Backup the data before exiting the program
_terminate() {
    printf "Backing up data before exiting program...\n"

    BACKED_UP=""
    while [ -z "${BACKED_UP}" ]; do
        _backup && BACKED_UP="1" || printf "Backup failed, retrying...\n"
        sleep 1
    done

    exit 0
}

# Run the program
_run() {
    # Create an infinite loop to backup data
    while true; do
        sleep "${BACKUP_INTERVAL:-42}"
        if [ -n "$BACKUP_INTERVAL" ]; then
            _backup && _healthy || _unhealthy
        fi
    done
}

# Initialize
_init() {
    printf "Initializing...\n"

    # Initialize healthy status
    _healthy

    # Restore
    if _is_dir_empty "${ALPHA}" || [ "${FORCE_INITIAL_RESTORE}" = "true" ]; then
        _restore || _fatal "Could not restore data"
    fi

    _run
}

_bootstrap

trap _terminate SIGHUP SIGINT SIGTERM
trap "_backup; _run" USR1
trap "_restore; _run" USR2
_init
