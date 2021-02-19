# Captive Portal ( NGINX- SSL - DEBIAN 10 )

Captive portal using NGINX, hostapd, create_ap and dnsmasq in debian 10

## 1. Install tools 
    sudo apt install nginx hostapd dnsmasq net-tools python3-acme python3-certbot python3-mock python3-openssl python3-pkg-resources python3-pyparsing python3-zope.interface python3-certbot-nginx git -y
   

## 2. Install Create AP
    git clone https://github.com/oblique/create_ap
    cd create_ap
    make install

## 3. DNSMASQ Configuration
    sudo nano /etc/dnsmasq.conf
    
    listen-address=::1,127.0.0.1,200.200.200.1
    interface=wlo1
    bind-interfaces
    domain=your.domain.com
    dhcp-option=3,200.200.200.1
    dhcp-option=6,200.200.200.1
    dhcp-range=200.200.200.10,200.200.200.250,255.255.255.0,12h
    log-queries
    address=/#/200.200.200.1
    address=/clients1.google.com/200.200.200.1
    address=/clients3.google.com/200.200.200.1
    address=/connectivitycheck.android.com/200.200.200.1
    address=/connectivitycheck.gstatic.com/200.200.200.1

## 4. Configure your web
    create folder 
    sudo mkdir /var/www/your.domain.com
    sudo mkdir /var/www/your.domain.com/captiveportal

    copy in the folder captiveportal your captive portal web 
    
## 5. SSL configuration
>Create a new SSL for test.

    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

## 6. OpenSSL strong DH group
> While we are using OpenSSL, we should also create a strong Diffie-Hellman group, which is used in negotiating Perfect Forward Secrecy with clients. 

    sudo openssl dhparam -out /etc/nginx/dhparam.pem 4096    

## 6.1 Self Signed
    create file self-signed.con in /etc/nginx/snippets/self-signed.conf

    and tape this:

        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    create file ssl-params.conf /etc/nginx/snippets/ssl-params.conf

    and tape this:

        ssl_protocols TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_dhparam /etc/nginx/dhparam.pem;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
        ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
        ssl_session_timeout  10m;
        ssl_session_cache shared:SSL:10m;
        ssl_session_tickets off; # Requires nginx >= 1.5.9
        ssl_stapling on; # Requires nginx >= 1.3.7
        ssl_stapling_verify on; # Requires nginx => 1.3.7
        resolver 200.200.200.1 200.200.200.1 valid=300s;
        resolver_timeout 5s;
        # Disable strict transport security for now. You can uncomment the following
        # line if you understand the implications.
        # add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";

## 7. Configuring Nginx to Use SSL
 
    sudo nano /etc/nginx/sites-enabled/default

    server {
        listen 80;
        listen [::]:80;

    server_name your.domain.com www.your.domain.com;

    return 302 https://$server_name$request_uri;
    }

    server {
        
        listen 443 ssl;
        listen [::]:443 ssl;
        
        include snippets/self-signed.conf;
        include snippets/ssl-params.conf;
        
        # Only allow GET, HEAD, POST
        if ($request_method !~ ^(GET|HEAD|POST)$) 
        { 
            return 444; 
        }

        # Logs
        access_log /var/log/nginx/captiveportal.access.log;
        error_log /var/log/nginx/captiveportal.error.log warn;

        root /var/www/your.domain.com;

        index index.html;

        server_name your.domain.com www.your.domain.com;

        # Handle iOS
        if ($http_user_agent ~* (CaptiveNetworkSupport) ) {
         return 302 http://$host/captiveportal;
     }


    # Default redirect for any unexpected content to trigger captive portal sign in screen on device.


    location / {
       return 302 http://$host/captiveportal;
    }
 
    location /captiveportal {
        # First attempt to serve request as file, then
        # as directory, then fall back to displaying a 404.
        try_files $uri $uri/ =404;
    }

    # Redirect these errors to the home page.
    error_page 401 403 404 =200 /captiveportal/index.html;
}	


# 8. Create Hotspot using create_ap

    sudo create_ap -n wlo1 CAPTIVE_PORTAL --no-virt --no-dnsmasq --redirect-to-localhost

# 9. Set WIFI DEVICE IP
> if no set this then DNSMASQ crash
> 
    sudo ifconfig wlo1 200.200.200.1

# 10. Start DNSMASQ

    sudo systemctl start dnsmasq.service 

# 11. Start NGINX SERVER

    sudo systemctl start nginx.service



Guide for [SSL-NGINX-DEBIAN](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-on-debian-10) 


> Testing with IP 192.168.X.X and 10.45.X.X FAIL CAPTIVE PORTAL in Samsung devices



   


