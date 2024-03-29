#!/usr/bin/env bats

load test_helper

setup() {
  echo `date` >> /tmp/debug.log
  echo "02_http: debug01" >> /tmp/debug.log

  start_docker_stack http
  if [ "$BATS_TEST_NUMBER" -eq 1 ]; then
    echo "# --- Test filename is $(basename ${BATS_TEST_FILENAME})" >&3
  fi
}

teardown() {
  clean_docker
}

@test "Check if HAProxy map is created" {

  echo `date` >> /tmp/debug.log
  echo "clean_cert: debug 02_http" >> /tmp/debug.log
  docker-compose ps >> /tmp/debug.log
  docker ps -a >> /tmp/debug.log

  clean_cert
  sleep 2
  run check_map_with_entry_set_to_no
  [ "$status" -eq 0 ]
}

@test "Check cert generation: Fresh state" {

  run check_for_http_200
  [ "$status" -eq 0 ]

  run bash -c "docker-compose logs haproxy | grep ' : Use cert generation method: ' | grep ': http'"
  [ "$status" -eq 0 ]

  run bash -c "docker-compose logs haproxy | tail -n 1 | grep ' : Removing lock'"
  [ "$status" -eq 0 ]

  run check_map_with_entry_set_to_no
  [ "$status" -eq 0 ]
}

@test "Check cert generation: Subsequent request" {
  run check_for_http_200
  [ "$status" -eq 0 ]

  run bash -c "docker-compose logs haproxy | grep ' : Use cert generation method: ' | grep ': http'"
  [ "$status" -eq 0 ]

  run bash -c "docker-compose logs haproxy | tail -n 1 | grep 'OK: Cert already there'"
  [ "$status" -eq 0 ]

  run check_map_with_entry_set_to_no
  [ "$status" -eq 0 ]
}
