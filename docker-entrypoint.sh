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

if [ ! -d "$SRC" ]; then
  echo "Directory $SRC DOES NOT exist."
  exit 1
elif [ ! -d "$DST" ]; then
  echo "Directory $DST DOES NOT exist."
  exit 1
fi

DELETE=${REPLICATE_DELETE:-yes}
if [ "$DELETE" == "yes" ]; then
  RSYNC_OPTIONS="--delete"
fi

echo "+ Replicating with rsync (RSYNC_OPTIONS=$RSYNC_OPTIONS)..."
rsync -av $RSYNC_OPTIONS $SRC/ $DST
echo "+ Done"
