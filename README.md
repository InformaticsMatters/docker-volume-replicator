# docker-volume-replicator (3.0)

![Architecture](https://img.shields.io/badge/architecture-amd64%20%7C%20arm64-lightgrey)
[![CodeFactor](https://www.codefactor.io/repository/github/informaticsmatters/docker-volume-replicator/badge)](https://www.codefactor.io/repository/github/informaticsmatters/docker-volume-replicator)

![GitHub tag (latest SemVer pre-release)](https://img.shields.io/github/v/tag/informaticsmatters/docker-volume-replicator?include_prereleases)

[![build latest](https://github.com/informaticsmatters/docker-volume-replicator/actions/workflows/build-latest.yaml/badge.svg)](https://github.com/informaticsmatters/docker-volume-replicator/actions/workflows/build-latest.yaml)
[![build tag](https://github.com/informaticsmatters/docker-volume-replicator/actions/workflows/build-tag.yaml/badge.svg)](https://github.com/informaticsmatters/docker-volume-replicator/actions/workflows/build-tag.yaml)

A simple container image that expects two volume mounts "/volume-a"
and "/volume-b" where data is replicated (using rsync) from one to the
other based on an environment variable whose value is either `AtoB` or `BtoA`.

When running the image...

1.  Mount volumes onto the paths `/volume-a` and `/volume-b`
2.  Set environment variable `REPLICATE_DIRECTION` (to either `AtoB` or `BtoA`)
3.  Set environment variable `REPLICATE_DELETE` to anything other than `yes`
    to avoid wiping the destination

In **2.0** you can use S3 as a destination or source. To do this you must set
`VOLUME_A_IS_S3` (where '/volume-a' is expected to be the S3 volume).
See the `docker-entrypoint.sh` for details of these and other related
environment variables.

In **3.0** rclone can be used to synchronise the volume to an S3 bucket.
We do this by setting `USE_RCLONE` (to `yes`) and providing values for
`AWS_ACCESS_KEY`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, and
`S3_BUCKET_NAME`.

In **3.1** you can use rclone to replicate to a sub-directory
that is different for each day of the week. By setting `USE_DOW_FOR_RCLONE` (to `yes`)
you can keep backups for up to a week i.e. using sub-directories **Monday**,
**Tuesday**, etc.

## Building the image
To build an image tagged `3.1.0` just run docker compose...

    $ export IMAGE_TAG=3.1.0
    $ docker compose build

And run typically with something like: -

    $ docker run --rm -e REPLICATE_DIRECTION=AtoB \
            -v $PWD/a:/volume-a \
            -v $PWD/b:/volume-b \
            informaticsmatters/volume-replicator:$IMAGE_TAG

---
