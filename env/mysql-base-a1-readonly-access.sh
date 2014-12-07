#!/bin/bash
#

set -u

## TO CHECK (old)
## mysql -u root -D mysql -e  'select * from db ; select * from user ' | grep -E 'av2s|av2t|av2_kiev' 

CONFIG_TAG=aviso-sources
CONFIG_ITEM=a1_kiev # I choose first

USER_SOURCE="$( k116-config ${CONFIG_FILE:+-c ${CONFIG_FILE}}   --Dump "${CONFIG_ITEM} user    "      $CONFIG_TAG)"
PASS_SOURCE="$( k116-config ${CONFIG_FILE:+-c ${CONFIG_FILE}}   --Dump "${CONFIG_ITEM} pass    "      $CONFIG_TAG)"

echo USER_SOURCE: $USER_SOURCE
echo PASS_SOURCE: $PASS_SOURCE

[ -z "${USER_SOURCE}" -o -z "${PASS_SOURCE}" ] && {
    echo "Error. Empty access data."
    exit 1
}

((1)) && {
    echo "Drop user '${USER_SOURCE}'."
    mysql -u root -e "DROP USER '${USER_SOURCE}'@'%'"
    mysql -u root -e "DROP USER '${USER_SOURCE}'@'localhost'"
    #mysql -u root -e "DROP USER '${USER_TARGET}'@'%'"
    #mysql -u root -e "DROP USER '${USER_TARGET}'@'localhost'"

    echo "Create user '${USER_SOURCE}'. Set passwd."
    mysql -u root -e "CREATE USER '${USER_SOURCE}'@'%'         IDENTIFIED BY '${PASS_SOURCE}'"
    mysql -u root -e "CREATE USER '${USER_SOURCE}'@'localhost' IDENTIFIED BY '${PASS_SOURCE}'"
    #mysql -u root -e "CREATE USER '${USER_TARGET}'@'%'         IDENTIFIED BY '${PASS_TARGET}'"
    #mysql -u root -e "CREATE USER '${USER_TARGET}'@'localhost' IDENTIFIED BY '${PASS_TARGET}'"
    echo
}


function prepare_access {
    echo "Preparation for ${SOURCE_DB}:"

#    echo "Revoke user '${USER_SOURCE}'."
#    mysql -u root -e "REVOKE ALL PRIVILEGES ON ${SOURCE_DB}.* FROM ${USER_SOURCE}"
#    mysql -u root -e "REVOKE GRANT OPTION   ON ${SOURCE_DB}.* FROM ${USER_SOURCE}"
#    #mysql -u root -e "REVOKE ALL PRIVILEGES ON ${TARGET_DB}.* FROM ${USER_TARGET}"
#    #mysql -u root -e "REVOKE GRANT OPTION   ON ${TARGET_DB}.* FROM ${USER_TARGET}"

    echo "Grant for '${USER_SOURCE}' Db: '${SOURCE_DB}'"
    mysql -u root -e "GRANT Select, Lock Tables ON ${SOURCE_DB}.* TO '${USER_SOURCE}'@'%';"
    mysql -u root -e "GRANT Select, Lock Tables ON ${SOURCE_DB}.* TO '${USER_SOURCE}'@'localhost';"
    #echo -e \\t ${USER_TARGET}:
    #mysql -u root -e "GRANT ALL PRIVILEGES  ON ${TARGET_DB}.* TO '${USER_TARGET}'@'%';"
    #mysql -u root -e "GRANT ALL PRIVILEGES  ON ${TARGET_DB}.* TO '${USER_TARGET}'@'localhost';"

#    mysql -u root -e "DROP USER '${USER_SOURCE}'@'%'"
#    mysql -u root -e "DROP USER '${USER_SOURCE}'@'localhost'"
    #mysql -u root -e "DROP USER '${USER_TARGET}'@'%'"
    #mysql -u root -e "DROP USER '${USER_TARGET}'@'localhost'"
}

for SOURCE_DB in a1_kiev a1_dnepr a1_odessa; do
    prepare_access
    echo
done



