


#mysql -u root -e 'drop database estate_dnepr'
#mysql -u root -e ' create database estate_dnepr'

for table in apartments areas  buildings commertial_estates  rooms; do
	mysql -u root -D estate_dnepr -e "truncate table $table"
done

#cat dump.sql | mysql -u root -D estate_dnepr
time perl a.pl >/dev/null 
