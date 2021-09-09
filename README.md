- master (Github Actions): [![Build Status](https://github.com/bjoernbessert/haproxy-cert-otf/actions/workflows/master.yml/badge.svg)](https://github.com/bjoernbessert/haproxy-cert-otf/actions)

-Deprecated:
- master (travis):  [![Build Status](https://travis-ci.com/bjoernbessert/haproxy-cert-otf.svg?branch=master)](https://travis-ci.com/bjoernbessert/haproxy-cert-otf/branches)  
- travis_ubuntu_haproxy_latest (travis): [![Build Status](https://travis-ci.com/bjoernbessert/haproxy-cert-otf.svg?branch=travis_ubuntu_haproxy_latest)](https://travis-ci.com/bjoernbessert/haproxy-cert-otf/branches)
- travis_ubuntu_haproxy_latest_stable_git (travis): [![Build Status](https://travis-ci.com/bjoernbessert/haproxy-cert-otf.svg?branch=travis_ubuntu_haproxy_latest_stable_git)](https://travis-ci.com/bjoernbessert/haproxy-cert-otf/branches)
- travis_ubuntu_haproxy_latest_development_git (travis): [![Build Status](https://travis-ci.com/bjoernbessert/haproxy-cert-otf.svg?branch=travis_ubuntu_haproxy_latest_development_git)](https://travis-ci.com/bjoernbessert/haproxy-cert-otf/branches)
- legacy (travis): [![Build Status](https://travis-ci.com/bjoernbessert/haproxy-cert-otf.svg?branch=legacy)](https://travis-ci.com/bjoernbessert/haproxy-cert-otf/branches)

# haproxy-cert-otf

Create SSL certificates on the fly with HAProxy. With the help of Lua the certificate is generated dynamically and transparently on the first request.

### Motivation

- Internal Domains (HTTPS-only)

    - No wildcard certs possible, because of domain structure with multiple different (sub)levels
    
- Internal Root-CA which creates certs and is imported in clients (browsers etc.) 

### Details

- Tested with (at least) the following HAProxy LTS releases: 2.4.0, 2.2.0
  - For prior versions (1.8.x, 2.0.x) see "legacy"-branch: https://github.com/bjoernbessert/haproxy-cert-otf/tree/legacy

- HAProxy configs: [Link](dockerfiles/haproxy/files)

- LUA script(s): [Link](lua_files)

### Using/Demo

- Install docker and docker-compose

- Build all container-images from dockerfiles/ (```make build```)

- Choose your certificate generation method:
    - ```export GET_CERT_METHOD=localca``` or ```export GET_CERT_METHOD=http```
    - "get_cert_method"
      - localca: Import the Root CA (ca.crt) [Link](dockerfiles/haproxy/files/generate-cert) into your client/browser or replace the ca-files with your own (and rebuild haproxy container)
      - http: Set an URL in get_cert_via_http() [Link](lua_files/on_the_fly_cert.lua)  where you can get the certs in *.pem-format

- ```docker-compose up -d```

- ```docker-compose logs -f haproxy```

- Direct your domain(s) to 127.0.0.1

- Certificates should now be generated on the fly, client/browser should not display any warning

### TODO

- Concurrency testing (Vegeta)
- DOC: Using a Intermediate CA with X.509 Name Constraints
- HAProxy multiple instances example for non-docker systems (maybe trough systemd)

### Possible Improvements

- Locking mechanism
  - since HAProxy 1.8:
    - Currently used: HAProxy maps + get/set via Lua
    - Future: Use HAProxy stick-tables + get/set via Lua (maybe possible with HAProxy 1.9 ('get' is possible with 1.9: https://www.arpalert.org/src/haproxy-lua-api/1.9dev/index.html#sticktable-class), or connect with tcp socket to local tcp HAProxy socket to execute commands)

- Load an index of all existing certs in memory on HAProxy startup (Lua + HAProxy stick-tables or Lua + HAProxy maps). Would save the filesystem lookups (maybe not an improvement at all because of already existing filesystem cache)

- Use 'luaossl" directly instead of openssl binary

- Do not start HAProxy as root (execute supervisortcl via sudo as haproxy user)

- Docker-specific: Mount (host-)volume for certs. If container is destroyed, certs doesnt have to generated again

- Auth-header (token or something) for HTTP-method
  
- Implement haproxy reload? (through supervisor?) - maybe faster than restart
  - maybe try supervisor + "-W" from haproxy

- Docker-specific: Two separate containers for the HAProxys (then maybe mount a volume with the certs into both containers)

### Testing

- Install **bats**:
  - ```sudo apt-get update && sudo apt-get -y install bats```

- ```make test```

- Run specific test
  - ```bats tests/$FILE.bats```

### Acknowledgments

- TimWolla/haproxy-auth-request https://github.com/TimWolla/haproxy-auth-request/blob/master/auth-request.lua

