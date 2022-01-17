# docker-volume-replicator (2.0)

[![CodeFactor](https://www.codefactor.io/repository/github/informaticsmatters/docker-volume-replicator/badge)](https://www.codefactor.io/repository/github/informaticsmatters/docker-volume-replicator)

A simple container image that expects two volume mounts `/volume-a`
and `/volume-b` where data is replicated (using rsync) from one to the
other based on an environment variable whose value is either `AtoB` or `BtoA`.

When running the image...

1.  Mount volumes onto the paths `/volume-a` and `/volume-b`
1.  Set environment variable `REPLICATE_DIRECTION` (to either `AtoB` or `BtoA`)
1.  Set environment variable `REPLICATE_DELETE` to anything other than `yes`
    to avoid wiping the destination

In **2.0** you can use S3 as a destination or source. To do this you must set
`REPLICANT_IS_S3` (where '/volume-a' is expected to be the S3 volume).
See the `docker-entrypoint.sh` for details of these and other related
environment variables.

## Building the image
Just run docker...

    $ docker-compose build

And run typically with something like: -

    $ docker run --rm -e REPLICATE_DIRECTION=AtoB \
            -v $PWD/a:/volume-a \
            -v $PWD/b:/volume-b \ 
            informaticsmatters/volume-replicator:2.0.0-rc.1

---
