#/bin/sh
CONST_DOMAIN='mydomain.com'
CONST_IP='200.200.200.1'
CONST_DHCP_RANGE='200.200.200.10,200.200.200.250,255.255.255.0,12h'

CONST_STR_DOMAIN_REPLACE='DOMAIN_NAME'
CONST_STR_IP_REPLACE='IP_ADDR'
CONST_DHCP_RANGE_REPLACE='DHCP_RANGE_STR'
CONST_WIFI_INTERFACE="WIFI_INTERFACE"

c_normal="\e[0m"
c_green="\e[32m"
c_yellow="\e[93m"

ok_with_color=$c_green"[ OK ]"$c_normal



echo -e $c_yellow"SETTING CAPTIVE PORTAL"$c_normal

read -p 'Domain (mydomain.com): ' domain
read -p 'IP (200.200.200.1): ' ipaddr
read -p 'DHCP-RANGE (200.200.200.10,200.200.200.250,255.255.255.0,12h): ' dhcprange

if [ -z "$domain" ]
then
    domain=$CONST_DOMAIN
fi

if [ -z "$ipaddr" ]
then
    ipaddr=$CONST_IP
fi

if [ -z "$dhcprange" ]
then
    dhcprange=$CONST_DHCP_RANGE
fi

echo -e $ok_with_color"  Domain: "$domain
echo -e $ok_with_color"  IP: "$ipaddr
echo -e $ok_with_color"  DHCP-RANGE: "$dhcprange



sudo apt install nginx hostapd dnsmasq net-tools python3-acme python3-certbot python3-mock python3-openssl python3-pkg-resources python3-pyparsing python3-zope.interface python3-certbot-nginx git make -y

git clone https://github.com/oblique/create_ap
make -C ./create_ap install

sudo cp -f _dnsmasq.conf /etc/dnsmasq.conf

sudo cp -f _nginx.conf /etc/nginx/sites-enabled/default

echo -e $c_yellow"Reset DNSMASQ.CONF"$c_normal

sudo sed -i "s/$CONST_STR_DOMAIN_REPLACE/$domain/" /etc/dnsmasq.conf
echo -e $ok_with_color"  Set domain name in dnsmasq.conf"

sudo sed -i "s/$CONST_STR_IP_REPLACE/$ipaddr/" /etc/dnsmasq.conf
echo -e $ok_with_color"  Set ip address in dnsmasq.conf"

sudo sed -i "s/$CONST_DHCP_RANGE_REPLACE/$dhcprange/" /etc/dnsmasq.conf
echo -e $ok_with_color"  Set dhcp_range in dnsmasq.conf"

echo -e $c_yellow"Reset NGINX.CONF"$c_normal

#ISSUE SAD command fail when in the same line exist many concurrency, in this case only two
sudo sed -i "s/$CONST_STR_DOMAIN_REPLACE/$domain/" /etc/nginx/sites-enabled/default
sudo sed -i "s/$CONST_STR_DOMAIN_REPLACE/$domain/" /etc/nginx/sites-enabled/default

echo -e $ok_with_color"  Set domain name in nginx.conf"

echo -e $c_yellow"Captive Portal Web Folder"$c_normal

sudo mkdir -p /var/www/$domain/captiveportal
echo -e $ok_with_color"  created folder /var/www/$domain/captiveportal"

sudo cp -f ./index.html /var/www/$domain/captiveportal/index.html
echo -e $ok_with_color"  copied index.html to /var/www/$domain/captiveportal/index.html"

echo -e $c_yellow"START OPEN SSL"$c_normal

#sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt
echo -e $ok_with_color" OpenSSL nginx selfsigned.key and nginx-selfsigned.crt"

echo -e $c_yellow"OpenSSL DHPARAM creating"$c_normal

#sudo openssl dhparam -out /etc/nginx/dhparam.pem 4096

echo -e $ok_with_color" OpenSSL Done"

sudo cp -f ./_self-signed.conf /etc/nginx/snippets/self-signed.conf
echo -e $ok_with_color" SELF-SIGN"
sudo cp -f ./_ssl-params.conf /etc/nginx/snippets/ssl-params.conf
echo -e $ok_with_color" SSL-PARAMS"

#ISSUE SAD command fail when in the same line exist many concurrency, in this case only two
sudo sed -i "s/$CONST_STR_IP_REPLACE/$ipaddr/" /etc/nginx/snippets/ssl-params.conf
sudo sed -i "s/$CONST_STR_IP_REPLACE/$ipaddr/" /etc/nginx/snippets/ssl-params.conf

echo -e $c_yellow'Starting HOTSPOT'$c_normal

read -p 'Captive Portal Name( CAPTIVE_PORTAL ): ' captive_name
if [ -z $captive_name ]
then
    captive_name='CAPTIVE_PORTAL'
fi

read -p 'Wifi interface name( wlo1 ): ' wifi_interface
if [ -z $wifi_interface ]
then
    wifi_interface='wlo1'
fi

sudo sed -i "s/$CONST_WIFI_INTERFACE/$wifi_interface/" /etc/dnsmasq.conf
echo -e $ok_with_color"  Set wifi interface in dnsmasq.conf"

sudo create_ap --daemon -n $wifi_interface $captive_name --no-virt --no-dnsmasq --redirect-to-localhost -g $ipaddr
sudo ifconfig $wifi_interface $ipaddr

echo -e $ok_with_color" Setting $wifi_interface IP: $ipaddr"

echo -e $ok_with_color" HOTSPOT"

sudo systemctl start dnsmasq.service
echo -e $ok_with_color" DNSMASQ SERVICE START"

sudo systemctl start nginx.service
echo -e $ok_with_color" NGINX SERVICE START"

echo -e $c_green"Done! Started Captive Portal "$c_normal
