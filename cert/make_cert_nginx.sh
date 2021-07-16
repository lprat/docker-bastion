#!/bin/bash
if [ $# -lt 1 ]; then
    echo ./make_cert_nginx password
    exit 1
fi
openssl genrsa -aes256 -passout pass:$1 -out nginx.pass.key 4096
openssl rsa -passin pass:$1 -in nginx.pass.key -out nginx.key
rm nginx.pass.key
openssl ecparam -genkey -name secp256r1 | openssl ec -out nginx.key
openssl req -new -key nginx.key -out nginx.csr
openssl x509 -req -days 730 -in nginx.csr -CA ca.pem -CAkey ca.key -set_serial 02 -out nginx.pem
openssl dhparam -out dhparams.pem 4096
