#!/bin/bash





USER=root
#PASS=
DATABASE=av2_clients
TABLE=orders

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

echo "Last records:"
mysql -t -u ${USER} ${PASS:+-p4${PASS}} -D ${DATABASE} -e "select * from ${TABLE} orders order by id desc limit 1"


echo "Real records:"
mysql -t -u ${USER} ${PASS:+-p4${PASS}} -D ${DATABASE} -e "select * from ${TABLE} orders where status is not null order by id desc"


echo
REAL_ID=$(mysql -N -B -u ${USER} ${PASS:+-p4${PASS}} -D ${DATABASE} -e "select id from ${TABLE} orders where status is not null order by id desc limit 1")
echo "REAL ID: $REAL_ID"


echo "Command to partial clean: "
CMD1="mysql -t -u ${USER} ${PASS:+-p4${PASS}} -D ${DATABASE} -e \"delete from ${TABLE} where id > ${REAL_ID}; select row_count(); \" "
echo $CMD1
((REAL_ID++))
CMD2="mysql -t -u ${USER} ${PASS:+-p4${PASS}} -D ${DATABASE} -e \" ALTER TABLE ${TABLE} AUTO_INCREMENT = ${REAL_ID} \" "
echo $CMD2

yes_no "Proceed ? [yes/no]: "
(($?)) && {
    echo "Performing:"
    eval "${CMD1}"
    eval "${CMD2}"
}

