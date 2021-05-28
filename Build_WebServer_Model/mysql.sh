#!/bin/bash

function installMysql() {
    #install dependances package
    installDepen=`yum install epel-release -y`

    #download mysqll ver 5.7
    wget=`wget http://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm -P /tmp/`

    #add repository
    repo=`rpm -Uvh /tmp/mysql57-community-release-el7-9.noarch.rpm`

    #install
    yumInstallMysql=`yum install mysql-server -y`

    #start service mysql
    serviceStart=`service mysqld start`

    #show passwd temp
    MYSQL_PASSWD=`grep 'password' /var/log/mysqld.log | grep -o "\localhost:.*" | cut -d " " -f2`
    echo 'Password Temporary: ' $MYSQL_PASSWD


    #mysql secure install
    mysql_secure_installation

}
