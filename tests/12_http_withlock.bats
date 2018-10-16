#!/usr/bin/env bats

load test_helper

setup() {
  start_docker_stack http
  if [ "$BATS_TEST_NUMBER" -eq 1 ]; then
    sleep 1
    docker-compose exec haproxy bash -c 'echo "set map /tmp/geo.map lock_cert yes" | nc 127.0.0.1 9999'
  fi
}

teardown() {
  clean_docker
}

@test "Check if HAProxy map is created" {
  sleep 1
  check_map_with_entry_set_to_yes
}

@test "Check cert generation: Fresh state" {
  clean_cert
  check_for_curl_cert_error
  check_map_with_entry_set_to_yes
  docker-compose logs haproxy | tail -n 1 | grep ' : Removing lock'
}

@test "Check cert generation: Subsequent request" {
  check_for_curl_cert_error
  check_map_with_entry_set_to_yes
  docker-compose logs haproxy | tail -n 1 | grep 'TODO: Fill out here'
}

