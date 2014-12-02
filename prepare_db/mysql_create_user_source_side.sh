
#!/bin/bash
#

## TO CHECK
## mysql -u root -D mysql -e  'select * from db ; select * from user ' | grep -E 'av2s|av2t|av2_kiev' 

set -u

USER_SOURCE='av2source'
USER_SOURCE_PASS='avS12'
SOURCE_DB='a1_kiev'

USER_TARGET='av2target'
USER_TARGET_PASS='avT14'
TARGET_DB='av2_kiev'

mysql -u root -e "DROP USER '${USER_SOURCE}'@'%'"
mysql -u root -e "DROP USER '${USER_SOURCE}'@'localhost'"
mysql -u root -e "DROP USER '${USER_TARGET}'@'%'"
mysql -u root -e "DROP USER '${USER_TARGET}'@'localhost'"

mysql -u root -e "CREATE USER '${USER_SOURCE}'@'%'         IDENTIFIED BY '${USER_SOURCE_PASS}'"
mysql -u root -e "CREATE USER '${USER_SOURCE}'@'localhost' IDENTIFIED BY '${USER_SOURCE_PASS}'"
mysql -u root -e "CREATE USER '${USER_TARGET}'@'%'         IDENTIFIED BY '${USER_TARGET_PASS}'"
mysql -u root -e "CREATE USER '${USER_TARGET}'@'localhost' IDENTIFIED BY '${USER_TARGET_PASS}'"

mysql -u root -e "REVOKE ALL PRIVILEGES ON ${SOURCE_DB}.* FROM ${USER_SOURCE}"
mysql -u root -e "REVOKE GRANT OPTION   ON ${SOURCE_DB}.* FROM ${USER_SOURCE}"
mysql -u root -e "REVOKE ALL PRIVILEGES ON ${TARGET_DB}.* FROM ${USER_TARGET}"
mysql -u root -e "REVOKE GRANT OPTION   ON ${TARGET_DB}.* FROM ${USER_TARGET}"

echo 'Users:'
echo -e \\t ${USER_SOURCE}:
mysql -u root -e "GRANT Select          ON ${SOURCE_DB}.* TO '${USER_SOURCE}'@'%';"
mysql -u root -e "GRANT Select          ON ${SOURCE_DB}.* TO '${USER_SOURCE}'@'localhost';"
echo -e \\t ${USER_TARGET}:
mysql -u root -e "GRANT ALL PRIVILEGES  ON ${TARGET_DB}.* TO '${USER_TARGET}'@'%';"
mysql -u root -e "GRANT ALL PRIVILEGES  ON ${TARGET_DB}.* TO '${USER_TARGET}'@'localhost';"



