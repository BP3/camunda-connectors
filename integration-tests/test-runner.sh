#!/bin/sh

############################################################################
#
# Licensed Materials - Property of BP3 Global
#
#  Connector Bundle
#
# Copyright © BP3 Global Inc 2026. All Rights Reserved.
# This software is subject to copyright protection under
# the laws of the United States, United Kingdom and other countries.
#
############################################################################

if [ `dirname $0` != "" ]; then
  cd `dirname $0`
fi

export CAMUNDA_VERSION=`grep '^versionCamundaServer=' ../gradle.properties | cut -d'=' -f2`
export IMAGE_NAME=ghcr.io/bp3/camunda-connectors
export IMAGE_REF=$1

echo "Running against Camunda version [${CAMUNDA_VERSION}]"

# Want to make sure that we have the image we are supposed to be working with
image=`docker images --format "{{.ID}} \t{{.Repository}} \t{{.Tag}}" --filter=reference="$IMAGE_NAME:$IMAGE_REF" | wc -l`
if [ $(( image )) -ne 1 ]; then
  echo "Image $IMAGE_NAME:$IMAGE_REF not found, so pull it from registry"
  docker pull $IMAGE_NAME:$IMAGE_REF
  if [ $? -ne 0 ]; then
    echo "Image $IMAGE_NAME:$IMAGE_REF not found in registry, so exit\!"
    exit 1
  fi
else
  echo "Docker image $IMAGE_NAME:$IMAGE_REF found"
fi

testStatus='Success'

# Each test's result is also written as JUnit XML, which CI publishes to the PR
results_dir=build/test-results
mkdir -p "$results_dir"
results_cases=$(mktemp)
tests_run=0
tests_failed=0
tests_time=0

# Adds a <testcase> for one test: $1 name, $2 exit code, $3 seconds, $4 log file
add_junit_case () {
  {
    echo "  <testcase classname=\"integration-tests\" name=\"$1\" time=\"$3\">"
    if [ "$2" -ne 0 ]; then
      echo "    <failure message=\"Exited with code $2\"/>"
    fi
    # Drop control characters XML can't hold, and split any ]]> so the CDATA stays valid
    printf '    <system-out><![CDATA['
    tr -d '\000-\010\013\014\016-\037' < "$4" | sed 's/]]>/]]]]><![CDATA[>/g'
    echo ']]></system-out>'
    echo '  </testcase>'
  } >> "$results_cases"
}

write_junit () {
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo "<testsuite name=\"integration-tests\" tests=\"$tests_run\" failures=\"$tests_failed\" errors=\"0\" time=\"$tests_time\">"
    cat "$results_cases"
    echo '</testsuite>'
  } > "$results_dir/integration-tests.xml"
  rm -f "$results_cases"
}

alias "docker-compose"='docker compose'
docker_tty_opts=-i

#
# This function will run a single test. It runs the actual test in a new shell.
# Since the test has "set -e" enabled then if it fails for any reason then it will cause the shell to terminate and
# return back here where we can run 'docker-compose down' to tidy everything up
# Longer-term it probably makes sense to make this function accept an array of tests
# which can all be run in the same docker compose session
#

run_test () {
  docker-compose -f $1 up -d
  echo Sleeping whilst compose stack comes up properly ...
  sleep 10

  echo "Running test $2"

  # Keep streaming the output to the log while capturing it for the JUnit report
  test_log=$(mktemp)
  rc_file=$(mktemp)
  start=$(date +%s)
  { DOCKER_TTY_OPTS=$docker_tty_opts /bin/sh tests/$2 "$IMAGE_REF"; echo $? > "$rc_file"; } 2>&1 | tee "$test_log"
  rc=$(cat "$rc_file")
  elapsed=$(( $(date +%s) - start ))

  tests_run=$(( tests_run + 1 ))
  tests_time=$(( tests_time + elapsed ))
  if [ $rc -ne 0 ]; then
    tests_failed=$(( tests_failed + 1 ))
  fi
  add_junit_case "`basename $2 .sh`" "$rc" "$elapsed" "$test_log"
  rm -f "$test_log" "$rc_file"
  if [ $rc -ne 0 ]; then
    echo "Test '$2' completed with an error (exit code '$rc')"
    testStatus='Failure'
  else
    echo "Test '$2' completed successfully (exit code '$rc')"
  fi

  docker-compose -f $1 down

  return $rc
}

tst_list=$(mktemp)
'ls' -1S tests/*.sh > "$tst_list"

while read tst; do
  next_tst=`basename "$tst"`
  run_test "docker-compose.yaml" "$next_tst"
done < "$tst_list"

rm -f "$tst_list"

write_junit

# See if ANY of the tests failed
if [ "$testStatus" = "Success" ]; then
  echo "All tests succeeded"
  rc=0
else
  echo "There were some test failures"
  rc=1
fi

exit $rc
