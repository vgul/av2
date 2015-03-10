#!/bin/bash


function yes_no {
    local TEXT="${1:-}"
    YES=
    while [ 0 ]; do
        read -p "${TEXT}" CHOICE
        shopt -s nocasematch
        case $CHOICE in
            y|ye|yes|1)
                YES=1
                break
                ;;
            n|no|0)
                YES=0
                break
                ;;
        esac
        shopt -u nocasematch
    done
    return $YES
}

echo mysql -u root -D av2_clients -e "select count(*) from sms where status is NULL "
mysql -u root -D av2_clients -e "select count(*) from sms where status is NULL "

yes_no "Delete: [yes/no]"
mysql -u root -D av2_clients -e "delete from sms where status is NULL ; select row_count(); "
