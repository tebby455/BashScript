#!/bin/bash
export AnException=100
export AnotherException=101
#======================================================================================
#                                                                                     #
#TITLE:         mysql_backup.sh                                                       #
#DESCRIPTION:   script for automating the daily mysql backups on development computer #
#AUTHOR:        huynx                                                                 #
#DATE:          27, April, 2021                                                       #
#USAGE:         ./mysql_backup.sh                                                     #
#                                                                                     #
#=====================================================================================#

# Date/time format MM-DD-YY
datetime=$(date +%F)

# directory for backup
BACKUP_DIR="/home/mysql_backup/$datetime"

# MySQL Username && Password

# Read Username && Password from file
filename='mysql.txt'
# read username and password
strUser=`cat $filename | grep username`
username=${strUser:9}

strPasswd=`cat $filename | grep passwd`
passwd=${strPasswd:7}


# Do not backup these file
# Example: start with mysql (^mysql) or end with _schema(_schema$)
IGNORE_DB="(^mysql|_schema$)"

# Login, if not in user root then run into sudo
# function mysql_login() {
#     local login=`mysql -u $username -p$passwd 2> errors.txt` 
#     local tmp=`cat errors.txt | grep ERROR`
#     # [[ $tmp =~ .*ERROR* ]] && echo "Found" || echo "Not found"
#     if [[ $tmp =~ .*ERROR.* ]] 
#     then
#         login=`sudo mysql -u $username -p$passwd`
#     else
#         login=`mysql -u $username -p$passwd`   
#     fi
#     echo $login
# }

function mysql_login() {
  local mysql_login="-u $username" 
  if [ -n "$passwd" ]; then
    local mysql_login+=" -p$passwd" 
  fi
  echo $mysql_login
}


function database_list() {
  local show_databases_sql="SHOW DATABASES WHERE \`Database\` NOT REGEXP '$IGNORE_DB'"
  echo $(mysql $(mysql_login) -e "$show_databases_sql"|awk -F " " '{if (NR!=1) print $1}')
}

function echo_status(){
  printf '\r'; 
  printf ' %0.s' {0..100} 
  printf '\r'; 
  printf "$1"'\r'
}

function backup_database(){
    backup_file="$BACKUP_DIR/$datetime.$database.sql.gz" 
    output+="$database => $backup_file\n"
    echo_status "...backing up $count of $total databases: $database"
    $(mysqldump $(mysql_login) $database 2>/dev/null | gzip -9 > $backup_file)
}

function backup_databases(){
  local databases=$(database_list)
  local total=$(echo $databases | wc -w | xargs)
  local output=""
  local count=1

  
    for database in $databases; do
        backup_database
        local count=$((count+1))
    done 

  echo -ne $output | column -t
}

function hr(){
  printf '=%.0s' {1..100}
  printf "\n"
}

function motd() {
    echo "=====>MySQL Backup Tool<====="
    echo "!Author: huynx"
    echo "=>Note: username&passwd in $filename"
    echo "=>File save default: $BACKUP_DIR<dbname>.sql.gz"
    echo
}

{
    motd
    hr
    echo
    mkdir -p $BACKUP_DIR
    backup_databases
    hr
    printf "All databases backed up!\n"
} || {
    printf "Backing up failed!\n"
} 
