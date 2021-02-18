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


## 5. Configuring Nginx to Use SSL
 
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


# 7. Create Hotspot using create_ap

    sudo create_ap -n wlo1 CAPTIVE_PORTAL --no-virt --no-dnsmasq --redirect-to-localhost

# 8. Set WIFI DEVICE IP
> if no set this then DNSMASQ crash
> 
    sudo ifconfig wlo1 200.200.200.1

# 9. Start DNSMASQ

    sudo systemctl start dnsmasq.service 

# 10. Start NGINX SERVER

    sudo systemctl start nginx.service



Guide for [SSL-NGINX-DEBIAN](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-on-debian-10) 


> Testing with IP 192.168.X.X FAIL CAPTIVE PORTAL
> 
> Testing with IP 10.45.0.1 FAIL CAPTIVE PORTAL



   


