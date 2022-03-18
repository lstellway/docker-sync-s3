# Sync Data to S3

Docker container image used to backup data to S3 using [AWS cli](https://github.com/aws/aws-cli).

## Environment Variables

This script utilizes the AWS command-line interface program.<br />
As a result, this program supports [related environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html).<br />
Refer to the [documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) to learn how to configure AWS cli _(including authentication)_.

-   `AWS_ACCESS_KEY_ID_FILE`
    -   Path to file containing S3 access key
-   `AWS_SECRET_ACCESS_KEY_FILE`
    -   Path to file containing S3 access secret
-   `FORCE_INITIAL_RESTORE` _(Default: `"false"`)_
    -   Whether or not to force a restore even if the `ALPHA` location is not empty
-   `BACKUP_INTERVAL` _(Default `42`)_
    -   Time _(in seconds)_ in between synchronization attempts
-   `S3_ENDPOINT_URL`
    -   S3 endpoint URL
-   `S3_SYNC_RESTORE_FLAGS`
    -   Flags passed to the [AWS cli `sync` subcommand](https://docs.aws.amazon.com/cli/latest/reference/s3/sync.html) during the initial data restore.
-   `S3_SYNC_BACKUP_FLAGS`
    -   Flags passed to the [AWS cli `sync` subcommand](https://docs.aws.amazon.com/cli/latest/reference/s3/sync.html) during a backup.

## Usage

The entrypoint command takes two arguments:

1. **"Alpha"** - The data location to backup
2. **"Beta"** - The destination to backup data to

**Pull the [docker image](https://hub.docker.com/r/lstellway/sync-s3)**

```sh
docker pull lstellway/sync-s3
```

**Run a container**

```sh
# This commanad will backup to an S3 bucket from the local `/data` directory
docker run --rm -it lstellway/sync-s3 /data s3://bucket/path/to/destination

# s3:// endpoints can be used for both "Alpha" and "Beta"
docker run --rm -it lstellway/sync-s3 s3://bucket1/path/to/destination s3://bucket2/path/to/destination
```

**Example Docker Compose**

```yml
---
version: "3"
services:
    sync-s3-test:
        command: ["/data", "s3://bucket/path/to/destination"]
        container_name: sync-s3-test
        environment:
            AWS_ACCESS_KEY_ID: xxxxxxxxxx
            AWS_SECRET_ACCESS_KEY: xxxxxxxxxxxxxxxxxxxx
            AWS_DEFAULT_REGION: nyc3
            S3_ENDPOINT_URL: https://nyc3.digitaloceanspaces.com
            FORCE_INITIAL_RESTORE: "true"
        # Stat file every 10 seconds.
        # This configuration allows for a ~15 minute startup time to download files:
        # 10s interval x 90 retries = 900s / 60 = 15min
        healthcheck:
            test: ["stat", "/tmp/running"]
            interval: 10s
            timeout: 5s
            retries: 90
            start_period: 5s
        image: lstellway/sync-s3
        volumes:
            - sync-s3-data:/data
volumes:
    sync-s3-data:
        name: sync-s3-data
```

**Immediately Invoke a Backup**

```sh
docker kill --signal=USR1 <container-name-or-id>
```

**Immediately Invoke a Restore**

```sh
docker kill --signal=USR2 <container-name-or-id>
```

## Resources

-   [GitHub Repository](https://github.com/lstellway/docker-sync-s3)
-   [Docker Hub Page](https://hub.docker.com/r/lstellway/sync-s3)
-   [Issues](https://github.com/lstellway/docker-sync-s3/issues)

## Credits

While working on my own solution for backing up data to S3 from containers, I came across the [elementar/docker-s3-volume](https://github.com/elementar/docker-s3-volume) project. While my solution was headed in the same direction, the project was a very useful reference which I was able to borrow some ideas from.
