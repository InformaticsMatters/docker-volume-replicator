#!/bin/bash

# Tests the rclone "First-Of-Month" sub-directory logic in docker-entrypoint.sh.
#
# The entrypoint is run in a Debian container (it needs bash 4.2+ and /volume-b)
# with stub 'date' and 'rclone' commands on the PATH. The stub 'date' returns
# FAKE_DAY_OF_MONTH for the day of the month, and the stub 'rclone' simply
# prints the destination it was given (its 3rd argument).
#
# Run from the repository root: -
#
#   ./tests/test-first-of-month.sh

set -e

IMAGE="debian:12.11-slim"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Runs the entrypoint in a container and prints the rclone destination.
#
# $1 The fake day of the month (e.g. "01")
# $2 The value of USE_FIRST_OF_MONTH_FOR_RCLONE
# $3 The value of USE_DOW_FOR_RCLONE
run_entrypoint() {
  docker run --rm \
    -v "${REPO_DIR}:/repo:ro" \
    -e FAKE_DAY_OF_MONTH="$1" \
    -e USE_FIRST_OF_MONTH_FOR_RCLONE="$2" \
    -e USE_DOW_FOR_RCLONE="$3" \
    -e REPLICATE_DIRECTION=BtoA \
    -e USE_RCLONE=yes \
    -e AWS_ACCESS_KEY_ID=key \
    -e AWS_SECRET_ACCESS_KEY=secret \
    -e AWS_DEFAULT_REGION=region \
    -e S3_BUCKET_NAME=bucket \
    "${IMAGE}" bash -c '
      mkdir -p /volume-b /stubs
      cat > /stubs/date <<"EOF"
#!/bin/bash
if [ "$1" == "+%d" ]; then
  echo "${FAKE_DAY_OF_MONTH}"
else
  /bin/date "$@"
fi
EOF
      cat > /stubs/rclone <<"EOF"
#!/bin/bash
echo "RCLONE_DESTINATION $3"
EOF
      chmod +x /stubs/date /stubs/rclone
      PATH="/stubs:${PATH}" /repo/docker-entrypoint.sh
    ' | grep '^RCLONE_DESTINATION ' | cut -d' ' -f2
}

FAILURES=0

# $1 Test name
# $2 Expected rclone destination
# $3 Actual rclone destination
expect_destination() {
  if [ "$3" == "$2" ]; then
    echo "PASS: $1"
  else
    echo "FAIL: $1 (expected destination '$2', got '$3')"
    FAILURES=$((FAILURES + 1))
  fi
}

expect_destination "First of month uses First-Of-Month" \
  "remote:/bucket/First-Of-Month" "$(run_entrypoint 01 yes no)"

expect_destination "Other days do not use First-Of-Month" \
  "remote:/bucket" "$(run_entrypoint 15 yes no)"

DESTINATION="$(run_entrypoint 15 yes yes)"
if [[ "$DESTINATION" =~ ^remote:/bucket/[1-7]-[A-Za-z]+day$ ]]; then
  echo "PASS: Other days keep the day-of-week sub-directory"
else
  echo "FAIL: Other days keep the day-of-week sub-directory (got '$DESTINATION')"
  FAILURES=$((FAILURES + 1))
fi

expect_destination "First of month replaces day-of-week" \
  "remote:/bucket/First-Of-Month" "$(run_entrypoint 01 yes yes)"

expect_destination "First of month ignored when not enabled" \
  "remote:/bucket" "$(run_entrypoint 01 no no)"

if [ "$FAILURES" -ne 0 ]; then
  echo "${FAILURES} test(s) failed"
  exit 1
fi
echo "All tests passed"
