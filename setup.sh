#/bin/sh
echo "SETTING CAPTIVE PORTAL"
sudo apt install nginx hostapd dnsmasq net-tools python3-acme python3-certbot python3-mock python3-openssl python3-pkg-resources python3-pyparsing python3-zope.interface python3-certbot-nginx git make -y

git clone https://github.com/oblique/create_ap
make -C ./create_ap install

sudo cp -f _dnsmasq.conf /etc/dnsmasq.conf

sudo mkdir /var/www/mydomain.com/captiveportal

sudo cp -C ./index.html /var/www/mydomain.com/captiveportal

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

sudo openssl dhparam -out /etc/nginx/dhparam.pem 4096

sudo cp -C ./_self-signed.conf /etc/nginx/snippets/self-signed.conf

sudo cp -C ./_ssl-params.conf /etc/nginx/snippets/ssl-params.conf


