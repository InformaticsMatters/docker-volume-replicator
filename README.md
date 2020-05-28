# docker-volume-replicator
A simple container image that expects two volume mounts "/volume-a"
and "/volume-b" where data is replicated (using rsync) from one to the
other based on an environment variable whose value is either `AtoB` or `BtoA`.

When running the image...

1.  Mount volumes onto the paths `/volume-a` and `/volume-b`
1.  Set environment variable `REPLICATE_DIRECTION`
1.  Set environment variable `REPLICATE_DELETE` to anything other than `yes`
    to avoid wiping the destination

---
