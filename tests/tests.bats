setup() {
    #TODO: Include flask container with cert api for testing http method
    #TODO: print output in bats output
    docker-compose up -d
}
teardown() {
    #docker-compose kill
    #docker-compose rm -f
    echo ""
}
@test "check cert generation" {
    run docker-compose exec haproxy bash -c 'echo "127.0.0.1 sub1.example.local" >> /etc/hosts'
    # TODO: curl with timeout
    # TODO: use "run" + native output function
    docker-compose exec haproxy curl -I -s "https://sub1.example.local" | grep 'HTTP/1.1 200 OK'
}
