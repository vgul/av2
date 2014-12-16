#!/bin/bash

set -u 

VALID_REGIONS='kiev|dnepr|odessa'

REGION=
while [ $# -gt 0 ]; do
    case "$1" in

       --help|-h|-\?)
            pod2usage -verbose 1 "$0"
            exit 1
            ;;

        --man)
            pod2usage -verbose 1 "$0"
            exit 1
            ;;

        --)
            # Rest of command line arguments are non option arguments
            shift # Discard separator from list of arguments
            break # Finish for loop
            ;;

        -*)
            echo "Unknown option: $1" >&2
            pod2usage --output ">&2" "$0"
            exit 2
            ;;

        *)
            [ -n "${REGION}" ] && {
                echo 'Too many region specified'
                exit 1
            }
            REGION=$1
            echo "$REGION" | grep -qP "^($VALID_REGIONS)$"
            (($?)) && {
                echo "$0: You have to specify one of '${VALID_REGIONS}'"
                exit 1
                
            }
            # Non option argument
            shift 
            # break # Finish for loop
            ;;
    esac
done

[ -z "${REGION}" ] && {
    echo "$0: You have to specify one of '${VALID_REGIONS}'"
    exit
}

ROOT_ACCESS=' -u root '
AV2_DB="aviso2"
TABLE_PRE="${REGION}_pre"
TABLE="${REGION}"
#TARGET_DB_PRE="av2_${REGION}_pre"

#mysql -u root -e "drop database if exists ${AV2_DB}"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${AV2_DB}"

mysql -u root -D ${AV2_DB} -e "DROP TABLE IF EXISTS ${TABLE_PRE}"

mysql -u root -D ${AV2_DB} -e "
CREATE TABLE IF NOT EXISTS ${TABLE_PRE} (
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
) DEFAULT CHARSET=utf8 ENGINE=MyISAM;
"

mysql -u root -D ${AV2_DB} -e "describe ${TABLE_PRE}"

## set param for SOURCE_DB, TARGET_DB, see README
time perl normalize_db.pl --region $REGION --dbname ${AV2_DB} --table-pre ${TABLE_PRE}
CODE=$?
echo CODE $CODE
((CODE)) && {
    echo Error
    exit 1
}

mysql -u root -D ${AV2_DB} -e "select count(*) from ${TABLE_PRE}"
mysql -u root -D ${AV2_DB} -e "drop table if exists ${TABLE}"
mysql -u root -D ${AV2_DB} -e "rename table ${TABLE_PRE} to ${TABLE}"
#mysqldump -u root ${TARGET_DB_PRE} | mysql -u root -D ${TARGET_DB}

exit

__END__

=pod
=head1 NAME

create-site-db.sh - Prepare db for zvonar....ua sites

=head1 SYNOPSIS

create-site-db.sh [OPTIONS] [kiev|odessa|dn

=head1 OPTIONS

=over 4

=item B<--help> | B<-h>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=cut


