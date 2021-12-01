#!/bin/bash

set -e
set -u

FQDN="${1}"
METHOD="${2}"
BASEDIR="/opt/generate-cert/"
HAPROXY_CERT_DIR='/etc/haproxy/certs/'
HAPROXY_CRT_STORE='/etc/haproxy/certs'
HAPROXY_SOCKET='/var/run/haproxy.sock'

CA_PRIVATE_KEY='../ca.key'
CA_CERT='../ca.crt'

local_ca () {
  mkdir -p $BASEDIR/certs_tmp
  cd $BASEDIR/certs_tmp

  openssl ecparam -name prime256v1 -genkey -noout -out ${FQDN}.key

  openssl req -subj "/CN=${FQDN}" -extensions v3_req -sha256 -new -key ${FQDN}.key -out ${FQDN}.csr

  openssl x509 -req -set_serial "0x$(openssl rand -hex 16)" -extensions v3_req -days 398 -sha256 -in ${FQDN}.csr -CA $CA_CERT -CAkey $CA_PRIVATE_KEY -CAcreateserial -out ${FQDN}.crt -extfile <(sed "s/subjectAltName = placeholder/subjectAltName = DNS:${FQDN}/" ../server_cert.cnf)

  cat ${FQDN}.crt $CA_CERT ${FQDN}.key > ${FQDN}.pem

  mv -f ${FQDN}.pem ${HAPROXY_CERT_DIR}

  configure_cert_in_haproxy
}


http () {
  configure_cert_in_haproxy
}


configure_cert_in_haproxy () {
  echo "${HAPROXY_CERT_DIR}${FQDN}.pem"

  # TODO: Why is this needed? Seems to active the socket or something
  echo "show info" | socat ${HAPROXY_SOCKET}  -

  echo "new ssl cert ${HAPROXY_CERT_DIR}${FQDN}.pem" | socat ${HAPROXY_SOCKET} -
  echo "show ssl cert" | socat ${HAPROXY_SOCKET} -
  echo -e "set ssl cert ${HAPROXY_CERT_DIR}${FQDN}.pem <<\n$(cat ${HAPROXY_CERT_DIR}${FQDN}.pem)\n" | socat ${HAPROXY_SOCKET} -
  echo "commit ssl cert ${HAPROXY_CERT_DIR}${FQDN}.pem" | socat ${HAPROXY_SOCKET} -
  echo "add ssl crt-list ${HAPROXY_CRT_STORE} ${HAPROXY_CERT_DIR}${FQDN}.pem" | socat ${HAPROXY_SOCKET} -
}


# entry point

$METHOD

