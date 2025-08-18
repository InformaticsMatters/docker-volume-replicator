# docker-volume-replicator (2.0)

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

## Building the image
Just run docker...

    $ docker compose build

And run typically with something like: -

    $ docker run --rm -e REPLICATE_DIRECTION=AtoB \
            -v $PWD/a:/volume-a \
            -v $PWD/b:/volume-b \
            informaticsmatters/volume-replicator:3.0.0

---
