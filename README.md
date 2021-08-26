# Docker BASTION

This docker BASTION is based on projet: https://guacamole.apache.org/, Authelia, nginx, https://github.com/siomiz/chrome.  

## Features
  - Guacamole with TOTP (google authentificator) allows access to RDP, VNC, SSH. 
  - Authelia allows access to all web admin portal 
  - Nginx like reverse proxy (TLS & certificat authentification) for guacamole and web portal admin (authelia).
  - Chrome browser to connect web portal admin (if you not use authelia & reverse proxy nginx)

## Usage Guacamole only
### Rsyslog config
In your rsyslog config (on your docker host):
  - make docker log directory: "mkdir -p /var/log/dockers/" 
  - Enable module TCP ('module(load="imtcp")') and listen on docker host ('input(type="imtcp" port="514" address="172.17.0.1")') 
  - Copy file "rsyslog-docker.conf" in "/etc/rsyslog.d/docker.conf" and reload rsyslogd

### Dns config
In your interne DNS serveur add bastion server resolution:
  - bastion.your_domaine.fr IN A X.X.X.X (X.X.X.X -> IP address bastion server)

### Certificat nginx config
First, get repository: git clone https://github.com/lprat/docker-bastion  
And go to directory "cert"  
    - make CA (see cert/Readme.md)
    - Make nginx.key, nginx.pem and dhparams.pem (see Readme.md) or import cert from your PKI
    - Create user certificat with script if you need for certificat client authentification (see cert/Readme.md)
      - if you use cert auth, un comment line in nginx_guac.conf:

```
#if ($ssl_client_verify != SUCCESS) {
#  return 403;
#}
```

### Nginx config
In "nginx_guac.conf": 
  - replace "bastion.exemple.com" by your host (ex: bastion.your_domaine.fr)
  - If you want add certificat client authentification then uncomment line after "#IF YOU WANT ADD CERTIFICAT AUTHENTIFICATION"

### Config authentification
You can config authentification guacamole in "docker-compose_guacamole.yml", by default TOTP is enable.  
Use environment variable to config auth (openid, cas, header, ldap, radius, duo), example:
```
LDAP_HOSTNAME=xxx.fr
LDAP_USER_BASE_DN=
LDAP_PORT=636
```
Ref: https://github.com/apache/guacamole-client/blob/master/guacamole-docker/bin/start.sh  

### Run docker-compose
```shell
docker-compose -f docker-compose_guacamole.yml up -d
```
If first time to run then after "docker-compose -f docker-compose_guacamole.yml up -d", run (create db):
```shell
sudo bash init.sh
```

### Connect to guacamole
Connect to guacamole : https://bastion.your_domaine.fr/ ( username is `guacadmin` with password `guacadmin` ) and create new admin and remove guacadmin account.  

#### Add chrome
Chrome is docker runned by docker-compose.  
Create new connexion to chrome (host: chrome / port: 5900 / protocol: VNC).  

#### Add RDP/VNC/SSH
When you add new RDP/VNC/SSH acces and it's work fine, you must apply local firewall rule (iptables/netfilter or windows firewall) on RDP/VNC/SSH to accept only "bastion (guacamole)" address IP. 

##### Share SSH
Just enable SFTP in configuration connexion.  

##### Share RDP
Create directory for server: "mkdir ($pwd)/docker-bastion/rdp_share/server_xxx"  
In connexion RDP configuration:  
  - In "Driver redirection" :  
    - Enable "driver network"  
    - Name of driver: "guacamole"  
    - Path to driver: "/share_rdp/server_xxx/"  
https://www.youtube.com/watch?v=TTFB2XEQQUU https://www.youtube.com/watch?v=TTFB2XEQQUU 
### Record session
For record session use directory: "/record" in guacamole config. 
You can use variable in name of file to record: http://guacamole.apache.org/doc/gug/configuring-guacamole.html#parameter-tokens  
#### Read session
To decode video and text use command docker:
```
docker exec guacd /usr/local/guacamole/bin/guaclog -f /record/file-to-extract 
#read with text editor /record/file-to-extract.txt
```
```
docker exec guacd /usr/local/guacamole/bin/guacenc -f /record/file-to-extract 
#read with vlc /record/file-to-extract.m4v
```

### Video to help you
https://www.youtube.com/watch?v=TTFB2XEQQUU  


## Usage Guacamole and authelia for web admin
### Rsyslog config
In your rsyslog config (on your docker host):
  - make docker log directory: "mkdir -p /var/log/dockers/" 
  - Enable module TCP ('module(load="imtcp")') and listen on docker host ('input(type="imtcp" port="514" address="172.17.0.1")') 
  - Copy file "rsyslog-docker.conf" in "/etc/rsyslog.d/docker.conf" and reload rsyslogd

### Dns config
In your interne DNS serveur add bastion server resolution:
   - bastion.your_domaine.fr IN A X.X.X.X (X.X.X.X -> IP address bastion server)
   - bastion.your_domaine.fr IN CNAME  authelia.your_domaine.fr (OU) authelia.your_domaine.fr IN A X.X.X.X (X.X.X.X -> IP address bastion server)
   - bastion.your_domaine.fr IN CNAME  vhost_web_portal_admin.your_domaine.fr  (OU) vhost_web_portal_admin.your_domaine.fr  IN A X.X.X.X (X.X.X.X -> IP address bastion server and vhost_web_portal_admin.your_domaine.fr -> it's vhost name use by user to connect to portal web_portal_admin.your_domaine.fr)

### Certificat nginx config
First, get repository: git clone https://github.com/lprat/docker-guacamole 
And go to directory "cert"
    - In directory "cert"
      - make CA (see Readme.md)
      - Make nginx.key and nginx.pem (see Readme.md) or import cert from your PKI
      - Create user certificat with script if you need (see Readme.md)
      
### Authelia config
In "authelia-conf/auth.conf" :
  - change "auth.example.com" by "authelia.your_domaine.fr"
In "authelia/configuration.yml" :
  - add user in users_database.yml
    - make password with command: "docker run --rm authelia/authelia:latest authelia hash-password 'yourpassword'"
In "authelia/configuration.yml" :
  - Change "jwt_secret" by a long secret string
  - Change "default_redirection_url" by your domaine URL with redirect if auth fail
  - Change "totp->issuer" by the name of totp get in you app google authentificator (name of account)
  - Add "vhost_web_portal_admin.your_domaine.fr" to protect in "access_control->rules" (remove exemple) - URL/VHOST (vhost_web_portal_admin.your_domaine.fr) doesnt URL/VHOST destination/final (web_portal_admin.your_domaine.fr) but URL/VHOST "middle" : Client -> URL/VHOST middle (bastion) -> URL/HOST final (web admin portal)
  - Change smtp configuration (you need smtp to send email with TOTP to client at first connect) "notifier->smtp->..."
    - If tls dont use, change "disable_require_tls" by "true"   

#### Add web portal admin
When you add new web portal admin, you must to modify in file:
  - User must exist in "authelia/users_database.yml", otherwise add it
  - In "authelia/configuration.yml" section "access_control" in "rules" add new host (your choice) for your web portal admin (ex: portal_admin.exemple.com -> bastion_portal_admin.exemple.com) and choose security level two_factor:
```
access_control:
  default_policy: deny
  rules:
    - domain: bastion_portal_admin.exemple.com
      policy: two_factor
```

You will try if work fine (check on https://bastion_portal_admin.exemple.com), and if it's ok then you can apply local firewall rule on web portal admin (ex: portal_admin.exemple.com) to accept only "bastion (reverse proxy nginx)" address IP.  
  
Choose user or group to give access, can use doc: https://www.authelia.com/docs/configuration/access-control.html  

### Nginx config
In "nginx_guac.conf": 
  - replace "bastion.exemple.com" by your host (ex: bastion.your_domaine.fr)
  - replace "authelia.your_domaine.fr" by your host
  - If you want protect web admin portal replace "vhost_web_portal_admin.your_domaine.fr" by your real vhost and "web_portal_admin.your_domaine.fr" by real web portal admin host destination. If you dont use, please remove or comment "server {}" part.
  - If you want add certificat client authentification then uncomment line after "#IF YOU WANT ADD CERTIFICAT AUTHENTIFICATION"

### Config authentification
You can config authentification guacamole in "docker-compose_guacamole.yml", by default TOTP is enable.  
Use environment variable to config auth (openid, cas, header, ldap, radius, duo), example:
```
LDAP_HOSTNAME=xxx.fr
LDAP_USER_BASE_DN=
LDAP_PORT=636
```
Ref: https://github.com/apache/guacamole-client/blob/master/guacamole-docker/bin/start.sh  

### Run docker-compose
```shell
docker-compose up -d
```

### Connect to guacamole
Connect to guacamole : https://bastion.your_domaine.fr/ and change default password ( username is `guacadmin` with password `guacadmin` ).

#### Add RDP/VNC/SSH
When you add new RDP/VNC/SSH acces and it's work fine, you must apply local firewall rule (iptables/netfilter or windows firewall) on RDP/VNC/SSH to accept only "bastion (guacamole)" address IP.  

### Connect to web admin by authelia
If you have added VHOST portal admin to protect, try if work fine: https://vhost_admin_portal/

