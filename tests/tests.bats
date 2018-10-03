setup() {
    #TODO: Include flask container with cert api for testing http method
    #TODO: print output in bats output
    docker-compose up -d

    run docker-compose exec haproxy bash -c 'echo "127.0.0.1 sub1.example.local" >> /etc/hosts'
}

teardown() {
    #docker-compose kill
    #docker-compose rm -f
    echo ""
}

@test "check cert generation clean" {

    docker-compose exec haproxy bash -c 'rm -f /etc/haproxy/certs/sub1.example.local.pem'
    docker-compose exec haproxy bash -c 'supervisorctl restart haproxy_back'

    # TODO: curl with timeout
    # TODO: use "run" + native output function
    docker-compose exec haproxy curl -I -s "https://sub1.example.local" | grep 'HTTP/1.1 200 OK'
}

@test "check cert generation subsequent request" {
    
    # TODO: curl with timeout
    # TODO: use "run" + native output function
    docker-compose exec haproxy curl -I -s "https://sub1.example.local" | grep 'HTTP/1.1 200 OK'
  
    # TODO: use "run" + native output function
    docker-compose logs haproxy | tail -n 1 | grep 'OK: Cert already there'
}

