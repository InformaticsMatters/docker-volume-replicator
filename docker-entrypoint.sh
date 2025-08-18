#!/bin/bash

# Controlled by the following ENV: -
#
#   REPLICATE_DIRECTION (AtoB or BtoA)
#   REPLICATE_DELETE (yes)
#   REPLICATE_QUIETLY (yes)
#
#   VOLUME_A_IS_S3 (just needs to exist)
#
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY
#   AWS_ENDPOINTS
#   AWS_DEFAULT_REGION
#   S3_BUCKET_NAME
#   S3_REQUEST_STYLE
#
#   USE_RCLONE Set to 'yes' to rclone to the (S3) destination

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
  exit
fi

echo "--] REPLICATE_DIRECTION is ${REPLICATE_DIRECTION}"
echo "--] SRC is ${SRC}"
echo "--] DST is ${DST}"
echo "--] REPLICATE_DELETE is ${REPLICATE_DELETE:-yes}"
echo "--] REPLICATE_QUIETLY is ${REPLICATE_QUIETLY:-yes}"

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
  : "${AWS_ACCESS_KEY_ID?Need to set AWS_ACCESS_KEY_ID}"
  : "${AWS_SECRET_ACCESS_KEY?Need to set AWS_SECRET_ACCESS_KEY}"
  : "${S3_BUCKET_NAME?Need to set S3_BUCKET_NAME}"

  echo "--] AWS_ACCESS_KEY_ID is (supplied)"
  echo "--] AWS_SECRET_ACCESS_KEY is (supplied)"
  echo "--] AWS_ENDPOINTS is ${AWS_ENDPOINTS}"
  echo "--] S3_BUCKET_NAME is ${S3_BUCKET_NAME}"
  echo "--] S3_REQUEST_STYLE is ${S3_REQUEST_STYLE}"

  # We'll use s3fs to mount the bucket so it can be used
  # as a conventional file-system.
  #
  # For this process to work the container MUST run in privileged mode.
  # e.g. - if launching with the docker command
  #        you must use add the `--privileged` option.

  # Put S3 credentials in a custom passwd file...
  echo "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" > /tmp/.passwd-s3fs
  chmod 600 /tmp/.passwd-s3fs

  # Any extra S3-Fuse args required?
  # i.e. is S3_URL or S3_REQUEST_STYLE defined?
  S3FS_EXTRA_OPTIONS=""
  if [ -n "$AWS_ENDPOINTS" ]; then
    S3FS_EXTRA_OPTIONS+="-o url=${AWS_ENDPOINTS}"
  fi
  if [ -n "$S3_REQUEST_STYLE" ]; then
    S3FS_EXTRA_OPTIONS+=" -o ${S3_REQUEST_STYLE}"
  fi

  # We create volume-a, but does volume-b exist?
  if [ ! -d "/volume-b" ]; then
    echo "Directory /volume-b DOES NOT exist."
    exit
  fi

  # Create the S3 mount point and then invoke s3fs
  mkdir -p /volume-a
  S3FS_CMD_OPTIONS="/volume-a -o passwd_file=/tmp/.passwd-s3fs ${S3FS_EXTRA_OPTIONS}"
  echo "--] s3fs S3_BUCKET_NAME=${S3_BUCKET_NAME}"
  echo "--] s3fs S3FS_CMD_OPTIONS=${S3FS_CMD_OPTIONS}"
  s3fs -d -o sigv2 ${S3_BUCKET_NAME} ${S3FS_CMD_OPTIONS}
  echo "--] s3fs started ($?)"

elif [ -v USE_RCLONE ]; then

  # Ensure the source volume exists...
  if [ ! -d "$SRC" ]; then
    echo "SRC directory ($SRC) DOES NOT exist."
    exit
  fi

else

  # Ensure the source and destination volumes exist...
  if [ ! -d "$SRC" ]; then
    echo "SRC directory ($SRC) DOES NOT exist."
    exit
  elif [ ! -d "$DST" ]; then
    echo "DST directory ($DST) DOES NOT exist."
    exit
  fi

fi

if [ "$USE_RCLONE" == "yes" ]; then

  if [ "$REPLICATE_DIRECTION" == "AtoB" ]; then
    echo REPLICATE_DIRECTION cannot be AtoB
    exit 1
  fi

  # Certain credentials are essential...
  : "${AWS_ACCESS_KEY_ID?Need to set AWS_ACCESS_KEY_ID}"
  : "${AWS_SECRET_ACCESS_KEY?Need to set AWS_SECRET_ACCESS_KEY}"
  : "${AWS_DEFAULT_REGION?Need to set AWS_DEFAULT_REGION}"
  : "${S3_BUCKET_NAME?Need to set S3_BUCKET_NAME}"

  echo "--] AWS_ACCESS_KEY_ID is (supplied)"
  echo "--] AWS_SECRET_ACCESS_KEY is (supplied)"
  echo "--] AWS_ENDPOINTS is ${AWS_ENDPOINTS}"
  echo "--] AWS_DEFAULT_REGION is ${AWS_DEFAULT_REGION}"
  echo "--] S3_BUCKET_NAME is ${S3_BUCKET_NAME}"

  DELETE=${REPLICATE_DELETE:-yes}
  if [ "$DELETE" == "yes" ]; then
    RCLONE_CMD="sync"
  else
    RCLONE_CMD="copy"
  fi

  echo "--] Replicating with rclone $RCLONE_CMD (S3_BUCKET_NAME=$S3_BUCKET_NAME)..."
  echo rclone $RCLONE_CMD $SRC remote:/$S3_BUCKET_NAME
  echo "--] Done"
  sleep 600

else

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

fi
