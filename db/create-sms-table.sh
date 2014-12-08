#!/bin/bash

set -u

AV2_CLIENT_DB='av2_clients'
AV2_SMS_TABLE='sms'


echo 'Detected: select count(*) from sms GROUP BY STATUS'
mysql -u root -D ${AV2_CLIENT_DB} -e "
    select count(*), status, region from sms GROUP BY status, region "

if ((1)); then
    echo
    while [ 0 ]; do
        read -p "Proceed drop/create ? [Yes/n]: " CHOICE
        shopt -s nocasematch
        case $CHOICE in
            y|yes)
                DO=1
                break;
                ;;
            n|no)
                echo 'Exiting'
                exit 0
                ;;
        esac
        shopt -u nocasematch
    done
fi

echo 'Perform drop/create.'
mysql -u root -D ${AV2_CLIENT_DB} -e "drop table if exists ${AV2_SMS_TABLE}"
mysql -u root -D ${AV2_CLIENT_DB} -e "
CREATE TABLE IF NOT EXISTS ${AV2_SMS_TABLE} (
    -- id      int(6) NOT NULL AUTO_INCREMENT,
    phone     INT(2),
    region    VARCHAR(8),
    stored    TIMESTAMP NOT NULL,
    scraped   DATE DEFAULT '0000-00-00',
    sent      TIMESTAMP DEFAULT '0000-00-00 00:00:00',
    delivered TIMESTAMP DEFAULT '0000-00-00 00:00:00',
    status    TINYINT,
    credits   DECIMAL(5,4),
    amount    DECIMAL(4,3),
    currency  VARCHAR(3),
    source    VARCHAR(128),
    KEY (phone)
)
"

