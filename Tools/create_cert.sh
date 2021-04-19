#!/bin/sh

openssl req -subj '/CN=XcodeSigner' -config ./Tools/cert.config -x509 -newkey rsa:2046 -keyout selfSignedKey.pem -out selfSigned.pem -days 365 -passout pass:"foobar"
openssl pkcs12 -export -out XcodeSigner.p12 -inkey selfSignedKey.pem -in selfSigned.pem -passin pass:"foobar" -passout pass:"foobar"
security import XcodeSigner.p12 -P foobar
