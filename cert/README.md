# CERTIFICAT 
You can use "CA" to use authentification by certificat.
## Generate CA
```
bash make_ca.sh PASSWORD_CA
```
## Generate Nginx certificate
If you dont have certificate in entreprise (PKI).

```
bash make_cert_nginx.sh PASSWORD_CERT
```

## Generate User certificate
Before use change "PASSROOT" in script "make_cert_user.sh by your key and verify right on bash file ("chmod 400 make_cert_user.sh").
```
$bash make_cert_user.sh mylogin
```
Get ID-mylogin.pfx and import in your browser (password import is in ID-mylogin.pwd).


