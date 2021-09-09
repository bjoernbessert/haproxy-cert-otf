function start_docker_stack()
{
  local METHOD="$1"

  if [ "$BATS_TEST_NUMBER" -eq 1 ]; then
    export "GET_CERT_METHOD=$METHOD"
    timeout 120 docker-compose up -d

    # Wait until haproxy container is truly ready
    for i in {1..150}; do
        echo `date` >> /tmp/debug.log
        echo "test_helper: debug01" >> /tmp/debug.log
        run docker-compose exec -T haproxy bash -c 'echo "show info" | nc 127.0.0.1 9999 | grep "Uptime:"' >> /tmp/debug.log
        if [ "$status" -eq 0 ]; then
            break
        fi
        if [ $i -eq 150 ]; then
            echo "start_docker_stack not successful. Exiting."
            exit 1
        fi
        sleep 0.2
    done

    #sleep 5
    echo `date` >> /tmp/debug.log
    echo "test_helper: debug02" >> /tmp/debug.log
    docker-compose exec -T haproxy bash -c 'echo "127.0.0.1 sub1.example.local" >> /etc/hosts' >> /tmp/debug.log
  fi
}

function clean_docker()
{
  if [ "$BATS_TEST_NUMBER" -eq ${#BATS_TEST_NAMES[@]} ]; then
    docker-compose kill
    docker-compose rm -f
    echo ""
  fi
}

function clean_cert()
{

  echo `date` >> /tmp/debug.log
  echo "clean_cert: debug0" >> /tmp/debug.log
  docker-compose ps >> /tmp/debug.log
  docker ps >> /tmp/debug.log

  echo `date` >> /tmp/debug.log
  echo "clean_cert: 1" >> /tmp/debug.log
  docker-compose exec -T haproxy bash -c 'rm -f /etc/haproxy/certs/sub1.example.local.pem' >> /tmp/debug.log

  echo `date` >> /tmp/debug.log
  echo "clean_cert: 2" >> /tmp/debug.log
  docker-compose exec -T haproxy bash -c 'supervisorctl restart haproxy ; sleep 2' >> /tmp/debug.log

}

function check_map_with_entry_set_to_no()
{
  docker-compose exec -T haproxy bash -c 'echo "show map /tmp/lock.map" | nc 127.0.0.1 9999 | grep "lock_cert no"'
}

function check_map_with_entry_set_to_yes()
{
  docker-compose exec -T haproxy bash -c 'echo "show map /tmp/lock.map" | nc 127.0.0.1 9999 | grep "lock_cert yes"'
}

function check_for_http_200()
{
  docker-compose exec -T haproxy bash -c "curl -I -s 'https://sub1.example.local' | grep 'HTTP/1.1 200 OK'"
}

function check_for_curl_cert_error()
{
  docker-compose exec -T haproxy bash -c "curl -I 'https://sub1.example.local' 2>&1 | grep 'SSL: no alternative certificate subject name matches target host name'"
}

