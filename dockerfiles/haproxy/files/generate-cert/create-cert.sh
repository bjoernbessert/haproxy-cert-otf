#!/bin/bash

set -e
set -u

FQDN="${1}"
HAPROXY_CERT_DIR='/etc/haproxy/certs/'
BASEDIR="/opt/generate-cert/"

mkdir -p $BASEDIR/certs_tmp
cd $BASEDIR/certs_tmp

openssl genrsa -out ${FQDN}.key 2048

openssl req -subj "/CN=${FQDN}" -extensions v3_req -sha256 -new -key ${FQDN}.key -out ${FQDN}.csr

openssl x509 -req -set_serial "0x$(openssl rand -hex 16)" -extensions v3_req -days 825 -sha256 -in ${FQDN}.csr -CA ../ca.crt -CAkey ../ca.key -CAcreateserial -out ${FQDN}.crt -extfile <(sed "s/subjectAltName = placeholder/subjectAltName = DNS:${FQDN}/" ../server_cert.cnf)

cat ${FQDN}.crt ../ca.crt ${FQDN}.key > ${FQDN}.pem

mv -f ${FQDN}.pem ${HAPROXY_CERT_DIR}

/usr/bin/timeout 5 /usr/bin/supervisorctl restart haproxy_back
