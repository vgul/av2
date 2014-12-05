

TARGET_DB='av2_kiev_pre' ## ./set_env.sh

mysql -u root -e "drop database if exists ${TARGET_DB}"
mysql -u root -e "create database ${TARGET_DB}"

mysql -u root -D ${TARGET_DB} -e "
CREATE TABLE av2data (
    ad_id          int(6) NOT NULL,
    cnt            INT(2) NOT NULL,
    ad_id_start    int(6) NOT NULL,
    body           varchar(512) NOT NULL,
    phones_to_page VARCHAR(128) NOT NULL,
    hier           varchar(128) NOT NULL,
    linear_name_translit
                   VARCHAR(128) NOT NULL,
    linear_name    VARCHAR(128) NOT NULL,
    idate          date NOT NULL,
    icnum          int(3) NOT NULL,
    type           VARCHAR(16) NOT NULL,
    num            INT(2) NOT NULL,
    page           INT(3) NOT NULL
    -- PRIMARY KEY (ad_id)
) DEFAULT CHARSET=utf8 ;
"

mysql -u root -D ${TARGET_DB} -e 'describe av2data'

#for table in apartments areas  buildings commertial_estates  rooms; do
#	mysql -u root -D estate_dnepr -e "truncate table $table"
#done

## set param for SOURCE_DB, TARGET_DB, set_env.sh see README
time perl normalize_db.pl
#time perl test.pl


## mysqldump -u root av2_kiev_pre | mysql -u root -D av2_kiev
