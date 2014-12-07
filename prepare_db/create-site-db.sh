#!/bin/perl

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
SOURCE="a1_${REGION}"
TARGET_DB="av2_${REGION}"
TARGET_DB_PRE="av2_${REGION}_pre"

mysql -u root -e "drop database if exists ${TARGET_DB_PRE}"
mysql -u root -e "create database ${TARGET_DB_PRE}"

mysql -u root -D ${TARGET_DB_PRE} -e "
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

mysql -u root -D ${TARGET_DB_PRE} -e 'describe av2data'

## set param for SOURCE_DB, TARGET_DB, see README
time perl normalize_db.pl $REGION
CODE=$?
echo CODE $CODE
((CODE)) && {
    echo Error
    exit 1
}

mysql -u root -D ${TARGET_DB_PRE} -e 'select count(*) from av2data  '

mysql -u root -e "create database if not exists ${TARGET_DB}"
mysqldump -u root ${TARGET_DB_PRE} | mysql -u root -D ${TARGET_DB}

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

=item B<--example1>

Show main data table for analyse

=back

=cut


