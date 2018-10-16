function start_docker_stack()
{
  local METHOD="$1"

  if [ "$BATS_TEST_NUMBER" -eq 1 ]; then
    export "GET_CERT_METHOD=$METHOD" 
    docker-compose up -d
    docker-compose exec haproxy bash -c 'echo "127.0.0.1 sub1.example.local" >> /etc/hosts'
  fi
}

function clean_docker()
{
  if [ "$BATS_TEST_NUMBER" -eq ${#BATS_TEST_NAMES[@]} ]; then
    docker-compose kill
    docker-compose rm -f
    echo 
  fi
}

function clean_cert()
{
  docker-compose exec haproxy bash -c 'rm -f /etc/haproxy/certs/sub1.example.local.pem'
  docker-compose exec haproxy bash -c 'supervisorctl restart haproxy_back'
}

function check_map_with_entry_set_to_no()
{
  docker-compose exec haproxy bash -c 'echo "show map /tmp/geo.map" | nc 127.0.0.1 9999 | grep "lock_cert no"'
}

function check_map_with_entry_set_to_yes()
{
  docker-compose exec haproxy bash -c 'echo "show map /tmp/geo.map" | nc 127.0.0.1 9999 | grep "lock_cert yes"'
}

function check_for_http_200()
{
  docker-compose exec haproxy curl -I -s "https://sub1.example.local" | grep 'HTTP/1.1 200 OK'
}

function check_for_curl_cert_error()
{
  run docker-compose exec haproxy curl -I -s "https://sub1.example.local" | grep 'SSL: no alternative certificate subject name matches target host name'
}

