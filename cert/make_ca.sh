#!/bin/bash
if [ $# -lt 1 ]; then
    echo ./make_ca password
    exit 1
fi
openssl genrsa -aes256 -passout pass:$1 -out ca.pass.key 4096
openssl rsa -passin pass:$1 -in ca.pass.key -out ca.key
rm ca.pass.key
openssl ecparam -genkey -name secp256r1 | openssl ec -out ca.key
#for 2 years => 730 days
openssl req -new -x509 -days 730 -key ca.key -out ca.pem
