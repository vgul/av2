#!/bin/bash


AP_SMS='-u root -D av2_clients'

SMS_TABLE='sms'


mysql $AP_SMS -e "DROP TABLE IF EXISTS ${SMS_TABLE}"

mysql $AP_SMS -e "
CREATE TABLE IF NOT EXISTS ${SMS_TABLE} (
    phone           INT(6) NOT NULL,
    region          VARCHAR(8) NOT NULL, 
    stored          TIMESTAMP NOT NULL,
    scraped         TIMESTAMP NOT NULL,
    sent            TIMESTAMP NOT NULL,
    source          VARCHAR(42),
    status          INT(1) DEFAULT NULL,
    currency        VARCHAR(5) NOT NULL,
    amount          DECIMAL(5,2) DEFAULT NULL,
    credits         DECIMAL(6,4) DEFAULT NULL,
    KEY (phone)
) DEFAULT CHARSET=utf8 ENGINE=InnoDB;
"

mysql $AP_SMS -e "describe ${SMS_TABLE}"



exit 0
__END__
[vlad@91:work.1 sms-feed]$ bash ./phones-thread.sh kiev --table0 --nhier 6 | head -51    | bash ./store-phone-to-send.sh 
ERROR 1146 (42S02) at line 2: Table 'av2_clients.sms' doesn't exist
insert PH=674174077 REGION=kiev SCRAPED=2015-02-10 SOURCE="aviso nhiers:6, ads:19"
ERROR 1146 (42S02) at line 2: Table 'av2_clients.sms' doesn't exist

