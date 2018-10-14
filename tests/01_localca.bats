#!/usr/bin/env bats

load test_helper

setup() {
  start_docker_stack local_ca
}

teardown() {
  clean_docker
}

@test "Check if HAProxy map is created" {
  sleep 1
  check_map_with_entry_set_to_no
}

@test "Check cert generation: Fresh state" {
  clean_cert
  check_for_http_200
  docker-compose logs haproxy | tail -n 1 | grep ' : Removing lock'
  check_map_with_entry_set_to_no
}

@test "Check cert generation: Subsequent request" {
  check_for_http_200
  docker-compose logs haproxy | tail -n 1 | grep 'OK: Cert already there'
  check_map_with_entry_set_to_no
}

