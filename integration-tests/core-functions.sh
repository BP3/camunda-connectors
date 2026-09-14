#!/bin/sh

############################################################################
#
# Licensed Materials - Property of BP3
#
#  Connector Bundle
#
# Copyright © BP3 Global Inc. 2025. All Rights Reserved.
# This software is subject to copyright protection under
# the laws of the United States and other countries.
#
############################################################################

# This is very early days so really expect this to change/evolve a lot - but you have to start somewhere

APP_JSON_HDR="Content-Type: application/json"

get_network_id () {
  network_id=`docker network ls --format "{{.Name}}" | grep camunda-platform`
}

assert_equals() {
  if [ "$1" -ne "$2" ]; then
    echo "** Assertion Failure: $1 does not equal $2"
    exit 1
  fi
}

assert_string_equals() {
  if [ "$1" != "$2" ]; then
    echo "** Assertion Failure: $1 does not equal $2"
    exit 1
  fi
}

assert_not_empty() {
  if [ ! "$2" ]; then
    echo "** Assertion Failure: $1 is empty"
    exit 1
  fi
}

assert_xml_match () {
  xmllint --format $1 > $1.format
  diff --ignore-all-space $2 $1.format
}
