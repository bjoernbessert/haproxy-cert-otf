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
    #TODO: remove entry from /etc/hosts
}

@test "check cert generation clean" {
    docker-compose exec haproxy bash -c 'rm -f /etc/haproxy/certs/sub1.example.local.pem'
    docker-compose exec haproxy bash -c 'supervisorctl restart haproxy_back'
    # TODO: curl with timeout
    # TODO: use "run" + native output function
    docker-compose exec haproxy curl -I -s "https://sub1.example.local" | grep 'HTTP/1.1 200 OK'
    docker-compose logs haproxy | tail -n 1 | grep ' : Removing lock'
}

@test "check cert generation subsequent request" {
    # TODO: curl with timeout
    # TODO: use "run" + native output function
    docker-compose exec haproxy curl -I -s "https://sub1.example.local" | grep 'HTTP/1.1 200 OK'
    # TODO: use "run" + native output function
    docker-compose logs haproxy | tail -n 1 | grep 'OK: Cert already there'
}

@test "check if HAProxy map is created" {
    # TODO: use "run" + native output function
    docker-compose exec haproxy bash -c 'echo "show map /tmp/geo.map" | nc 127.0.0.1 9999 | grep "lock_cert no"'
}

# TODO: Testcase: If lock is set
# echo "set map /tmp/geo.map lock_cert yes" | nc 127.0.0.1 9999

