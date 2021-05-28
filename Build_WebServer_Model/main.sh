#!/bin/bash
source mysql.sh
source webserver.sh

#==============================================================================================
#                                                                                             #
#TITLE:         BuildWebServer                                                                #
#DESCRIPTION:   tool for automation deloying a web server with Apache & Nginx (reverse proxy) #
#AUTHOR:        huynx                                                                         #
#DATE:          27, May, 2021                                                                 #
#USAGE:         ./main.sh                                                                     #
#                                                                                             #
#==============================================================================================

disableService

installMysql
installWebServer
installPHP

createuser
createVhostApache

setupWordpress
setupNginx

restartService
allowPermission

#reboot machine to disable selinux
init 6

echo "Finished"








