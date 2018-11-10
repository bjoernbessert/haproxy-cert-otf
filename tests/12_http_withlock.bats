#!/usr/bin/env bats

load test_helper

setup() {
  start_docker_stack http
  if [ "$BATS_TEST_NUMBER" -eq 1 ]; then
    echo "# --- Test filename is $(basename ${BATS_TEST_FILENAME})" >&3

    sleep 1
    docker-compose exec haproxy bash -c 'echo "set map /tmp/lock.map lock_cert yes" | nc 127.0.0.1 9999'
  fi
}

teardown() {
  clean_docker
}

@test "Check if HAProxy map is created" {
  sleep 1
  run check_map_with_entry_set_to_yes
  [ "$status" -eq 0 ]
}

@test "Check cert generation: Fresh state" {
  clean_cert
  run check_for_curl_cert_error
  [ "$status" -eq 0 ]
  run check_map_with_entry_set_to_yes
  [ "$status" -eq 0 ]
  run bash -c "docker-compose logs haproxy | grep ' : Use cert generation method: ' | grep ': http'"
  [ "$status" -eq 0 ]
  run bash -c "docker-compose logs haproxy | tail -n 3 | head -n 1 | grep ' : Lock not free. Cannot set lock'"
  [ "$status" -eq 0 ]
}

@test "Check cert generation: Subsequent request" {
  run check_for_curl_cert_error
  [ "$status" -eq 0 ]
  run check_map_with_entry_set_to_yes
  [ "$status" -eq 0 ]
  run bash -c "docker-compose logs haproxy | grep ' : Use cert generation method: ' | grep ': http'"
  [ "$status" -eq 0 ]
  run bash -c "docker-compose logs haproxy | tail -n 3 | head -n 1| grep ' : Lock not free. Cannot set lock'"
  [ "$status" -eq 0 ]
}
