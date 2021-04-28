
###########################################
#                                         #
# Author: huynx                           #
#                                         #
#                                         #
###########################################

#import library
import os
import time
import datetime
import pipes
import MySQLdb


# Date time
DATE_TIME = time.strftime('%Y-%m-%d')

# Backup directory
BACKUP_DIR = '/media/huynx/Data/backup_mysql/' + DATE_TIME

# Ignore databases
# Example: start with mysql (^mysql) or end with _schema(_schema$)
IGNORE_DB = '(^mysql|_schema$)'

# setup connect MySQLdb, check parameter is HOST, USER, PASSWD
def getParameter(x):
    check = str(x).upper()
    f = open("python_mysql.txt", "r")
    tmp = f.read().splitlines()
    f.close()
    if check == 'HOST':
        check = serverHost = tmp[0].split("=")[1]
    
    if check == 'USER':
        check = serverUser = tmp[1].split("=")[1]

    if check == 'PASSWD':
        check = serverPasswd = tmp[2].split("=")[1]
    return check
    

def getDatabaseList():
    conn = MySQLdb.connect(host = getParameter('host'), user = getParameter('user'), passwd = getParameter('passwd'))
    cur = conn.cursor()
    cur.execute("SHOW DATABASES WHERE `Database` NOT REGEXP \"" + IGNORE_DB + "\"")
    result = cur.fetchall()
    cur.close()
    conn.close()
    
    return result

def backupDatabases(listDatabases):
    count = 0
    print("Backing up database!!!")
    for database in listDatabases:
        databaseName = database[0]
        count += 1
        print("...backing up ", count, "of ", len(listDatabases), "database: ", databaseName)
        dumpcmd = "mysqldump -h " + getParameter('host') + " -u " + getParameter('user') + " -p" + getParameter('passwd') + " " + databaseName + " 2>/dev/null | gzip -9 > " + BACKUP_DIR + "/" + databaseName + ".sql.gz"
        os.system(dumpcmd)
        print(databaseName + " => " + BACKUP_DIR + "/" + databaseName + ".sql.gz\n") 

def main():
    
    os.system("mkdir -p " + BACKUP_DIR)
    try:
        backupDatabases(getDatabaseList())
        print("All databases backed up!\n")
    except:
        print("Backing up failed\n")

main()
    
