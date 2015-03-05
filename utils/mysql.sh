#!/usr/bin/env bash

# References:
# ----------------------------------------------------
# To check if we have a good user and pass
# 
# mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "show databases"
# 
# ${?} Returns 0 if good, 1 if bad
# ----------------------------------------------------
# *** REQUIRES ROOT ***
# To create the user, database, and grant privs
# 
# mysql --raw --silent -u ${sqlUser} -p${sqlPass} << EOF
# CREATE USER '${sqlUser}'@'localhost' IDENTIFIED BY  '${sqlPass}';
# GRANT USAGE ON * . * TO  '${sqlUser}'@'localhost' IDENTIFIED BY  '${sqlPass}' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;
# CREATE DATABASE IF NOT EXISTS  ${sqlDBname} ;
# USE ${sqlDBname};
# CREATE TABLE users (nuh VARCHAR(255), nick VARCHAR(255), seen INT(255), seensaid VARCHAR(255), karma INT(255));
# GRANT ALL PRIVILEGES ON  ${sqlDBname} . * TO  '${sqlDBname}'@'localhost';
# EOF
# 
# Returns nothing
# ----------------------------------------------------
# To show what databases we have access to
# 
# mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "use ${sqlDBname}"
# 
# ${?} Returns 0 if good, 1 if bad
# ----------------------------------------------------
# To check and see if a user is in the database
# 
# mysql --raw --silent -u ${sqlUser} -p${sqlPass} << EOF
# use ${sqlDBname}
# select * from users where nuh = '${sqlNuh}';
# EOF
# 
# Returns data if found, returns nothing if not
# ----------------------------------------------------
# To print specific information on a user
# 
# mysql --raw --silent -u ${sqlUser} -p${sqlPass} << EOF
# use ${sqlDBname}
# select ${sqlValue} from users where nuh = '${sqlNuh}';
# EOF
# 
# Possibilities for ${sqlValue}: nuh, nick, seen, seensaid, seensaidin, karma
# 
# Returns data if found, returns nothing if not
# ----------------------------------------------------
# To add a new user to the database
# 
# mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "use ${sqlDBname}; INSERT INTO users VALUES ('${sqlNuh}','${sqlNick},'${sqlSeen}','${sqlSeenSaid}','${sqlSeenSaidIn}','0');"
# 
# Returns nothing
# ----------------------------------------------------
# To update a user's information in the database
# 
# mysql --raw --silent -u ${sqlUser} -p${sqlPass} << EOF
# use ${sqlDBname}
# update users set ${sqlValue} = '${newValue}' where nuh = '${sqlNuh}';
# EOF
# 
# Possibilities for ${sqlValue}: nuh, nick, seen, seensaid, seensaidin, karma
# 
# Returns nothing
# ----------------------------------------------------

echo "This will create the needed mysql --raw --silent user and database for PuddingBot."
echo "To do this, a mysql --raw --silent account with all privilages (usually root) is needed."
echo "The bot will not be using this account at all. It's merely needed to"
echo "create the username and database for the bot to use, which will be"
echo "restricted to the bot only."
echo ""
read -p "Press [Enter] to continue, or Ctrl+C to quit." null
echo ""
read -p "Please enter desired MySQL username (to be created): " sqlUser
read -p "Please enter desired MySQL password (to be created): " sqlPass
echo "Please enter desired MySQL database name (to be created)"
read -p "(Normally, the same as chosen username is fine): " sqlDBname
echo ""
echo "Please set your MySQL information in your config with the following:"
echo ""
echo "# MySQL Username"
echo "sqlUser=\"${sqlUser}\""
echo "# MySQL password"
echo "sqlPass=\"${sqlPass}\""
echo "# MySQL Database Name. Usually the username is fine."
echo "sqlDBname=\"${sqlDBname}\""
echo ""
read -p "Press [Enter] to continue, or Ctrl+C to quit." null
echo ""
read -p "Please enter mysql --raw --silent root (or all privs) username: " sqlRootUser
read -p "Please enter ${sqlRootUser}'s password: " sqlRootPass
echo ""

echo "Testing for good username and password..."
mysql --raw --silent -u ${sqlRootUser} -p${sqlRootPass} -e "show databases" > /dev/null 2>&1
if [ "${?}" -eq "0" ]; then
	echo "Username and password good. Continuing..."
else
	echo "Bad username or password. Exiting."
	exit 255
fi

echo "Attempting to create user..."
mysql --raw --silent -u ${sqlRootUser} -p${sqlRootPass} -e "CREATE USER '${sqlUser}'@'localhost' IDENTIFIED BY  '${sqlPass}';"
if [ "${?}" -eq "0" ]; then
	echo "User created. Continuing..."
else
	echo "Unable to create user. Exiting."
	exit 255
fi

echo "Attempting to grant user usage..."
mysql --raw --silent -u ${sqlRootUser} -p${sqlRootPass} -e "GRANT USAGE ON * . * TO  '${sqlUser}'@'localhost' IDENTIFIED BY  '${sqlPass}' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;"
if [ "${?}" -eq "0" ]; then
	echo "User usage granted. Continuing..."
else
	echo "Unable to grant user usage. Exiting."
	exit 255
fi

echo "Attempting to create database..."
mysql --raw --silent -u ${sqlRootUser} -p${sqlRootPass} -e "CREATE DATABASE IF NOT EXISTS ${sqlDBname} ;"
if [ "${?}" -eq "0" ]; then
	echo "Database created. Continuing..."
else
	echo "Unable to create database. Exiting."
	exit 255
fi

echo "Attempting to create tables..."
mysql --raw --silent -u ${sqlRootUser} -p${sqlRootPass} -e "USE ${sqlDBname}; CREATE TABLE seen (nuh VARCHAR(255), nick VARCHAR(255), seen INT(255), seensaid VARCHAR(255), seensaidin VARCHAR(255));"
if [ "${?}" -ne "0" ]; then
	echo "Unable to create tables. Exiting."
	exit 255
fi
mysql --raw --silent -u ${sqlRootUser} -p${sqlRootPass} -e "USE ${sqlDBname}; CREATE TABLE karma (nick VARCHAR(255), value INT(255));"
if [ "${?}" -ne "0" ]; then
	echo "Unable to create tables. Exiting."
	exit 255
fi
mysql --raw --silent -u ${sqlRootUser} -p${sqlRootPass} -e "USE ${sqlDBname}; CREATE TABLE factoids (id VARCHAR(255), fact VARCHAR(255), locked INT(255), created VARCHAR(255), createdon INT(255), updated VARCHAR(255), updatedon INT(255), callno INT(255), calledby VARCHAR(255));"
if [ "${?}" -eq "0" ]; then
	echo "Tables created. Continuing..."
else
	echo "Unable to create tables. Exiting."
	exit 255
fi

echo "Attempting to convert tables to UTF-8..."
echo "Converting 'seen' table..."
arr=("nuh" "nick" "seensaid" "seensaidin")
echo "Converting 'karma' table..."
for i in "${arr[@]}"; do
	mysql --raw --silent -u ${sqlRootUser} -p${sqlRootPass} -e "USE ${sqlDBname}; ALTER TABLE seen CHANGE ${i} ${i} VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;"
	if [ "${?}" -ne "0" ]; then
		echo "Unable to convert ${i} to UTF-8. Exiting."
		exit 255
	fi
done
arr=("nick")
echo "Converting 'factoid' table..."
for i in "${arr[@]}"; do
	mysql --raw --silent -u ${sqlRootUser} -p${sqlRootPass} -e "USE ${sqlDBname}; ALTER TABLE seen CHANGE ${i} ${i} VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;"
	if [ "${?}" -ne "0" ]; then
		echo "Unable to convert ${i} to UTF-8. Exiting."
		exit 255
	fi
done
arr=("id" "fact" "created" "updated" "calledby")
for i in "${arr[@]}"; do
	mysql --raw --silent -u ${sqlRootUser} -p${sqlRootPass} -e "USE ${sqlDBname}; ALTER TABLE seen CHANGE ${i} ${i} VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;"
	if [ "${?}" -ne "0" ]; then
		echo "Unable to convert ${i} to UTF-8. Exiting."
		exit 255
	fi
done
echo "Tables converted. Continuing..."

echo "Attempting to grant database permissions..."
mysql --raw --silent -u ${sqlRootUser} -p${sqlRootPass} -e "GRANT ALL PRIVILEGES ON  ${sqlDBname} . * TO  '${sqlDBname}'@'localhost';"
if [ "${?}" -eq "0" ]; then
	echo "Database permissions granted. Continuing..."
else
	echo "Unable to grant database permissions. Exiting."
	exit 255
fi
