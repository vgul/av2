#!/bin/bash
set -u
AV2_CLIENT_DB='av2_clients'
AV2_CLIENT_TABLE='orders'

mysql -u root -e "drop database if exists ${AV2_CLIENT_DB}"
mysql -u root -e "create database if not exists ${AV2_CLIENT_DB}"

mysql -u root -D ${AV2_CLIENT_DB} -e "drop table if exists ${AV2_CLIENT_TABLE}"

mysql -u root -D ${AV2_CLIENT_DB} -e "
CREATE TABLE IF NOT EXISTS ${AV2_CLIENT_TABLE} (
    id             int(4) NOT NULL AUTO_INCREMENT,
    order_id       VARCHAR(16) NOT NULL,
    amount         DECIMAL(5,2),
    minus          DECIMAL(4,2),
    phone          VARCHAR(16),
    status         VARCHAR(16),
    tran_id        INT(6),
    type           VARCHAR(16),
    info           VARCHAR(64),
    ad_id          int(6) DEFAULT NULL,
    date1          TIMESTAMP NOT NULL,
    date2          TIMESTAMP,
    PRIMARY KEY (id,order_id)
) AUTO_INCREMENT=79 DEFAULT CHARSET=utf8 ;
"

mysql -u root -D ${AV2_CLIENT_DB} -e "insert into ${AV2_CLIENT_TABLE} set order_id='79k-1234',
     info='Initial insert',
     minus=8.88,
     phone='380670011001' "

mysqldump -u root --extended-insert=FALSE ${AV2_CLIENT_DB}
exit 

__END__
POST "/liqpay".
Routing to controller "Av::Index" and action "liqpay".
params: amount,currency,description,liqpay_order_id,order_id,public_key,receiver_commission,sender_phone,signature,status,transaction_id,type
amount: 0.10
currency: UAH
description: some
liqpay_order_id: 110172u1417612154798848
order_id: some
public_key: i71804176847
receiver_commission: 0.00
sender_phone: 380506182598
signature: qQ+cPZCITZBdIoFOGKuOrbC1TSw=
status: success
transaction_id: 45646512
type: buy
200 OK (0.003368s, 296.912/s).
