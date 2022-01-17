#!/bin/sh

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
# Here we essentially copy the logic from our 'bandr' repository.
# If using S3 the user sets the variable 'REPLICANT_IS_S3'
# and then sets 'REPLICANT_VOLUME' to 'A' or 'B' depending
# om the direction.
#
# (see https://github.com/s3fs-fuse/s3fs-fuse)
if [ -v REPLICANT_IS_S3 ]; then
  echo "--] Replicant is S3"

  # Certain credentials are essential...
  : "${S3_ACCESS_KEY_ID?Need to set S3_ACCESS_KEY_ID}"
  : "${S3_SECRET_ACCESS_KEY?Need to set S3_SECRET_ACCESS_KEY}"
  : "${REPLICANT_VOLUME?Need to set REPLICANT_VOLUME}"
  : "${S3_BUCKET_NAME?Need to set S3_BUCKET_NAME}"

  if [ "$REPLICANT_VOLUME" == "A" ]; then
    echo "--] Replicant volume is $REPLICANT_VOLUME"
  elif [ "$REPLICANT_VOLUME" == "B" ]; then
    echo "--] Replicant volume is $REPLICANT_VOLUME"
  else
    echo "--] Replicant volume must be A or B not $REPLICANT_VOLUME"
    exit 1
  fi
  S3_VOLUME_ID=$(echo "${REPLICANT_VOLUME}" | tr '[:upper:]' '[:lower:]')

  echo "--] S3_ACCESS_KEY_ID is (supplied)"
  echo "--] S3_SECRET_ACCESS_KEY is (supplied)"
  echo "--] S3_BUCKET_NAME is ${AWS_BUCKET_NAME}"
  echo "--] BACKUP_VOLUME_S3_URL is ${BACKUP_VOLUME_S3_URL}"
  echo "--] BACKUP_VOLUME_S3_REQUEST_STYLE is ${BACKUP_VOLUME_S3_REQUEST_STYLE}"
  if [ -n "${POST_DEBUG+x}" ]; then
    echo "--] POST_DEBUG = (defined)"
  else
    echo "--] POST_DEBUG = (not defined)"
  fi

  # We'll use s3fs to mount the bucket so it can be used
  # as a conventional file-system.
  #
  # For this process to work the container MUST run in privileged mode.
  # e.g. - if launching with the docker command
  #        you must use add the `--privileged` option.

  # Put AWS credentials in a custom passwd file...
  echo "${S3_ACCESS_KEY_ID}:${S3_SECRET_ACCESS_KEY}" > /tmp/.passwd-s3fs
  chmod 600 /tmp/.passwd-s3fs

  # Any extra S3-Fuse args required?
  # i.e. is BACKUP_VOLUME_S3_URL or BACKUP_VOLUME_S3_REQUEST_STYLE defined?
  S3FS_EXTRA_OPTIONS=""
  if [ -n "$BACKUP_VOLUME_S3_URL" ]; then
    S3FS_EXTRA_OPTIONS+="-o url=${BACKUP_VOLUME_S3_URL}"
  fi
  if [ -n "$BACKUP_VOLUME_S3_REQUEST_STYLE" ]; then
    S3FS_EXTRA_OPTIONS+=" -o ${BACKUP_VOLUME_S3_REQUEST_STYLE}"
  fi

  # Create the replicant mount point (volume A or B)
  # and then invoke s3fs
  mkdir -p "/volume-${S3_VOLUME_ID}"
  S3FS_CMD_OPTIONS="/volume-${S3_VOLUME_ID} -o passwd_file=/tmp/.passwd-s3fs ${S3FS_EXTRA_OPTIONS}"
  echo "--] s3fs AWS_BUCKET_NAME=${S3_BUCKET_NAME}"
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

echo "--] Replicating with rsync (RSYNC_XTRA_OPTIONS=$RSYNC_XTRA_OPTIONS)..."
rsync -av --exclude-from='./rsync-exclude.txt' $RSYNC_XTRA_OPTIONS $SRC/ $DST
echo "--] Done"
