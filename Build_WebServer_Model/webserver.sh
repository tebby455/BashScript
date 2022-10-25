#!/bin/bash

function disableService() {
    #turn off firewall/iptables
    systemctl disable firewalld
    turnoffFirewall=`service firewalld stop`

    #disable selinux
    echo "sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config"
    setenforce 0

    #disable php-fpm because we use default handler of apache
    systemctl disable php-fpm
    #systemctl disable php56-php-fpm

    service php-fpm stop
    #serivce php56-php-fpm start


}

function installWebServer() {
    yum install httpd -y
    yum install nginx -y 
}

function installPHP(){

    yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm

    yum -y install yum-utils

    yum-config-manager --disable remi-php54

    yum-config-manager --enable remi-php73

    yum -y install php php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-mcrypt php-mbstring php-curl php-xml php-pear php-bcmath php-json

    #yum -y install php56-php-cli php56-php-fpm php56-php-mysqlnd php56-php-zip php56-php-devel php56-php-gd php56-php-mcrypt php56-php-mbstring php56-php-curl php56-php-xml php56-php-pear php56-php-bcmath php56-php-json

}

function createuser(){
    read -p 'Input your username to add: ' username
    useradd $username
    mkdir /home/$username/public_html
}

function createVhostApache() {

    mkdir /etc/httpd/vhost.d 

    read -p 'Input your name of file .conf: ' fileConfig
    read -p 'Input your ServerName: ' ServerName

    #change port
    sed -i 's/Listen\ 80/Listen\ 8080/' /etc/httpd/conf/httpd.conf

    echo "<VirtualHost *:8080>

    ServerName $ServerName
    ServerAlias www.$ServerName
    DocumentRoot /home/$username/public_html
    #ScriptAlias /cgi-bin/ /home/$username/public_html/cgi-bin/

    <Directory /home/$username/public_html>

        #Add default index
        #DirectoryIndex
        Require all granted
        Options +Indexes +FollowSymLinks +ExecCGI
        AllowOverride All
    </Directory>
    </VirtualHost>" > /etc/httpd/vhost.d/$fileConfig.conf

    #test virtual host with phpinfo
    echo "<?php phpinfo(); ?>" > /home/$username/public_html/info.php
    echo "IncludeOptional vhost.d/*.conf" >> /etc/httpd/conf/httpd.conf

}


function setupWordpress() {
    wget http://wordpress.org/latest.tar.gz -P /home/$username/public_html/
    echo `cd /home/$username/public_html && tar -xvzf latest.tar.gz`

    cp /home/$username/public_html/wordpress/wp-config-sample.php /home/$username/public_html/wordpress/wp-config.php

    echo "====Mysql Creating Information===="
    read -p 'Enter your database: ' database_name
    read -p 'Enter your username: ' mysql_username
    echo "Your username will be: $mysql_username@localhost"
    echo -n 'Enter your password (At least A-Z, a-z, special character): ' 
    read mysql_password
    echo "=================================="

    echo "Enter your root password" 
    mysql -uroot -p -e "CREATE DATABASE $database_name;create user '$mysql_username'@'localhost' identified by '$mysql_password';grant all privileges on $database_name.* to '$mysql_username'@'localhost';flush privileges;"

    sed -i s/database_name_here/$database_name/ /home/$username/public_html/wordpress/wp-config.php
    sed -i s/username_here/$mysql_username/ /home/$username/public_html/wordpress/wp-config.php
    sed -i s/password_here/$mysql_password/ /home/$username/public_html/wordpress/wp-config.php
}

function setupNginx() {
    echo "server {
    listen 80;
    server_name $ServerName www.$ServerName;
    root /home/$username/public_html;

    location / {
        try_files \$uri \$uri/ /index.php /info.php;
    }

    location /wordpress {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ~ \.php$ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
    }
} " > /etc/nginx/conf.d/$ServerName.conf

}

function restartService() {
    systemctl enable httpd
    service httpd restart

    systemctl enable nginx
    service nginx restart
}

function allowPermission() {
    chown -R $username:$username /home/$username
    chmod -R 755 /home/$username
}

