#!/bin/bash

# Controlled by the following ENV: -
#
#   REPLICATE_DIRECTION
#   REPLICATE_DELETE (yes)
#   REPLICATE_QUIETLY (yes)
#
#   VOLUME_A_IS_S3 (just needs to exist)
#   S3_ACCESS_KEY
#   S3_SECRET_KEY
#   S3_BUCKET_NAME
#   S3_URL
#   S3_REQUEST_STYLE

# Is the replica direction set?
: "${REPLICATE_DIRECTION?is not set}"
# And a valid value?
case "$REPLICATE_DIRECTION" in
 AtoB) SRC="/volume-a"
       DST="/volume-b"
       ;;
 BtoA) SRC="/volume-b"
       DST="/volume-a"
       ;;
esac
if [ -z "$SRC" ]; then
  echo "ERROR: Invalid REPLICATE_DIRECTION \"$REPLICATE_DIRECTION\""
  exit 1
fi

# Is S3 the origin (AtoB) or destination (BtoA)?
# Here we've copied much of the logic from our 'bandr' repository.
#
# If using S3 for volume-a the user sets the variable 'VOLUME_A_IS_S3'
# and this code mounts the S3 bucket at /volume-a.
#
# (see https://github.com/s3fs-fuse/s3fs-fuse)
if [ -v VOLUME_A_IS_S3 ]; then
  echo "--] Volume A is S3"

  # Certain credentials are essential...
  : "${S3_ACCESS_KEY?Need to set S3_ACCESS_KEY}"
  : "${S3_SECRET_KEY?Need to set S3_SECRET_KEY}"
  : "${S3_BUCKET_NAME?Need to set S3_BUCKET_NAME}"

  echo "--] S3_ACCESS_KEY is (supplied)"
  echo "--] S3_SECRET_KEY is (supplied)"
  echo "--] S3_BUCKET_NAME is ${S3_BUCKET_NAME}"
  echo "--] S3_URL is ${S3_URL}"
  echo "--] S3_REQUEST_STYLE is ${S3_REQUEST_STYLE}"

  # We'll use s3fs to mount the bucket so it can be used
  # as a conventional file-system.
  #
  # For this process to work the container MUST run in privileged mode.
  # e.g. - if launching with the docker command
  #        you must use add the `--privileged` option.

  # Put S3 credentials in a custom passwd file...
  echo "${S3_ACCESS_KEY}:${S3_SECRET_KEY}" > /tmp/.passwd-s3fs
  chmod 600 /tmp/.passwd-s3fs

  # Any extra S3-Fuse args required?
  # i.e. is S3_URL or S3_REQUEST_STYLE defined?
  S3FS_EXTRA_OPTIONS=""
  if [ -n "$S3_URL" ]; then
    S3FS_EXTRA_OPTIONS+="-o url=${S3_URL}"
  fi
  if [ -n "$S3_REQUEST_STYLE" ]; then
    S3FS_EXTRA_OPTIONS+=" -o ${S3_REQUEST_STYLE}"
  fi

  # Create the S3 mount point and then invoke s3fs
  mkdir -p /volume-a
  S3FS_CMD_OPTIONS="/volume-a -o passwd_file=/tmp/.passwd-s3fs ${S3FS_EXTRA_OPTIONS}"
  echo "--] s3fs S3_BUCKET_NAME=${S3_BUCKET_NAME}"
  echo "--] s3fs S3FS_CMD_OPTIONS=${S3FS_CMD_OPTIONS}"
  s3fs ${S3_BUCKET_NAME} ${S3FS_CMD_OPTIONS}
fi

# Ensure the source and destination volumes exist...
if [ ! -d "$SRC" ]; then
  echo "Directory $SRC DOES NOT exist."
  exit 1
elif [ ! -d "$DST" ]; then
  echo "Directory $DST DOES NOT exist."
  exit 1
fi

DELETE=${REPLICATE_DELETE:-yes}
if [ "$DELETE" == "yes" ]; then
  RSYNC_XTRA_OPTIONS="--delete"
fi

QUIET=${REPLICATE_QUIETLY:-yes}
if [ "$QUIET" == "yes" ]; then
  RSYNC_QUIET="--quiet"
fi

echo "--] Replicating with rsync (RSYNC_XTRA_OPTIONS=$RSYNC_XTRA_OPTIONS)..."
rsync -a --exclude-from='./rsync-exclude.txt' $RSYNC_XTRA_OPTIONS $RSYNC_QUIET $SRC/ $DST
echo "--] Done"
