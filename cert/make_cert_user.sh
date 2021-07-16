#!/bin/bash
if [ $# -lt 1 ]; then
    echo ./make_cert_user user
    exit 1
fi
#get current id
id=$(cat currentid.txt | tr -d '\n')
i=$((id+1))
if [ $i -lt 10 ]
then
  id="0$i"
else
  id=$i
fi
echo $i > currentid.txt
PWD=`openssl rand -base64 32`
echo "$PWD" > $id-$1.pwd
chmod 400 $id-$1.pwd
echo Create user $1 avec id $id -- password: $PWD
PASSROOT='XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
openssl genrsa -aes256 -passout pass:$PASSROOT -out $id-$1.pass.key 4096
openssl rsa -passin pass:$PASSROOT -in $id-$1.pass.key -out $id-$1.key
rm $id-$1.pass.key
openssl ecparam -genkey -name secp256r1 | openssl ec -out $id-$1.key
openssl req -new -key $id-$1.key -out $id-$1.csr -subj "/C=FR/ST=Paris/L=Paris/O=ANS/CN=exemple.fr"
openssl x509 -req -days 730 -in $id-$1.csr -CA ca.pem -CAkey ca.key -set_serial $id -out $id-$1.pem
openssl pkcs12 -export -out $id-$1.full.pfx -inkey $id-$1.key -in $id-$1.pem -certfile ca.pem -passin pass:$PWD -passout pass:$PWD
