# haproxy-cert-otf

Create SSL certificates on the fly with HAProxy. With the help of Lua the certificate is generated dynamically on the first request.

### Motivation

- Internal Domains (HTTPS-only)

    - No wildcard certs possible, because of domain structure with multiple different (sub)levels
    
- Internal Root-CA which creates certs and is imported in clients (browsers etc.) 

### Details

- Tested with HAProxy 1.8.14

- HAProxy configs: [Link](dockerfiles/haproxy/files)

- LUA script(s): [Link](lua_files)

- Why 2 HAProxy instances?
  - At the moment it's not possible in HAProxy to add certs at runtime (maybe this will be possible in HAProxy 1.9). Therefore a reload is needed after adding a cert
  - If you have a single HAProxy instance, you can't reload this instance itself, because an connection is already established and would be stay on the old process and will not get the newly generated cert


### Using/Demo

- Install docker and docker-compose

- Build all container-images from dockerfiles/ (```make build```)

- Choose your certificate generation method:
    - ```export GET_CERT_METHOD=local_ca``` or ```export GET_CERT_METHOD=http```
    - "get_cert_method"
      - local_ca: Import the Root CA (ca.crt) [Link](dockerfiles/haproxy/files/generate-cert) into your client/browser or replace the ca-files with your own (and rebuild haproxy container)
      - http: Set an URL in get_cert_via_http() [Link](lua_files/on_the_fly_cert.lua)  where you can get the certs in *.pem-format

- ```docker-compose up -d```

- ```docker-compose logs -f haproxy```

- Direct your domain(s) to 127.0.0.1

- Certificates should now be generated on the fly, client/browser should not display any warning

### TODO

- get_cert_via_http()
  - DNS-Resolving
- HAProxy multiple instances example for non-docker systems (maybe trough systemd)

### Possible Improvements

- Implement locking mechanism (preventing the generation of certificates for same FQDN at the same time)
  - HAProxy 1.8:
    - Use HAProxy stick-tables + get/set via Lua (connect with tcp socket to local tcp HAProxy socket to execute commands)
    - Use HAProxy maps + get/set via Lua
  - HAProxy 1.9: Use HAProxy stick-tables + get/set directly from Lua (currently, only read operations possible)

- Load an index of all existing certs in memory on HAProxy startup (Lua + HAProxy stick-tables or Lua + HAProxy maps). Would save the filesystem lookups.

- Do not start HAProxy as root (execute supervisortcl via sudo as haproxy user)

- Docker-specific: Mount (host-)volume for certs. If container is destroyed, certs doesnt have to generated again

- Auth-header (token or something) for HTTP-method

- Implement Lets Encrypt for public domains
  
- Implement haproxy reload? (through supervisor?) - maybe faster than restart
  - maybe try supervisor + "-W" from haproxy

- Docker-specific: Two separate containers for the HAProxys (then maybe mount a volume with the certs into both containers)

### Testing

- Install **bats**:
  - https://github.com/bats-core/bats-core#installing-bats-from-source
  - https://github.com/bats-core/bats-core/releases

- Choose certificate generation method in Lua file

- ```make test```


### Acknowledgments

- TimWolla/haproxy-auth-request https://github.com/TimWolla/haproxy-auth-request/blob/master/auth-request.lua

