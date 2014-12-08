#!/bin/bash

set -u

EFFSCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
MY_PATH="$(dirname "${EFFSCRIPT}")/"
APP0="$(basename $EFFSCRIPT)"

TMPDIR="/tmp/$APP0-$$-$RANDOM"
trap "[ -d \"${TMPDIR}\" ] && : echo rm -rf \"${TMPDIR}\" && rm -rf \"${TMPDIR}\" " EXIT 
mkdir -p $TMPDIR

VALID_REGIONS='kiev|dnepr|odessa'
AP=
REGION=
TABLE0=
NHIER=
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

        --table0)
            TABLE0=1
            shift;
            ;;

        --nhier)
            shift
            while [ $# -gt 0 ]; do
                echo "$1" | grep -vqP '^\d'
                ((!$?)) && break 1
                NHIER="$NHIER $1"
                shift
            done
            NHIER=$(echo ${NHIER:1} | sed -e 's/ /,/g' )
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
                echo "$0: Generate plain text with phone."
                echo "$0: You have to specify one of '${VALID_REGIONS}'"
                exit 1

            }
            shift
            # Non option argument
            #break # Finish for loop
            ;;
    esac
done

[ -z "${REGION}" ] && {
    echo "$0: Generate plain text with phone."
    echo "$0: You have to specify one of '${VALID_REGIONS}'"
    exit
}

CONFIG_TAG=aviso-sources
CONFIG_ITEM="a1_${REGION}"

USER_SOURCE="$( k116-config ${CONFIG_FILE:+-c ${CONFIG_FILE}}   --Dump "${CONFIG_ITEM} user    "      $CONFIG_TAG)"
PASS_SOURCE="$( k116-config ${CONFIG_FILE:+-c ${CONFIG_FILE}}   --Dump "${CONFIG_ITEM} pass    "      $CONFIG_TAG)"
HOST_SOURCE="$( k116-config ${CONFIG_FILE:+-c ${CONFIG_FILE}}   --Dump "${CONFIG_ITEM} host    "      $CONFIG_TAG)"
AP=" -u $USER_SOURCE -p${PASS_SOURCE} -D ${CONFIG_ITEM} -h $HOST_SOURCE "
#echo AP $AP

[ -n "${TABLE0}" -o -z "${NHIER}" ] && {
    mysql -t --raw $AP -e  "
        select
            count(distinct body.ad_id) n_ad,
            synd.nhier,
            count(distinct phonen) n_ph,
            MAX(idate),
            MIN(idate),
            SUBSTR(GROUP_CONCAT(distinct phonen),1,20) some_phones
        FROM
            synd
        LEFT JOIN phones ON
            synd.ad_id = phones.ad_id
        LEFT JOIN body ON
            synd.ad_id = body.ad_id
        GROUP BY
            nhier
        ORDER BY 
            nhier
    " | sed -e 's/^/#/' > $TMPDIR/table0
}

if [ -n "${TABLE0}" ]; then
    echo '# n_ph  - Nuber of phones'
    echo '# n_ad  - count(distinct body.ad_id) - number of adverts'
    echo '# nhier - How many rubrics for phones group' 
    cat $TMPDIR/table0
fi


if [ -z "${NHIER}" ]; then
   NHIER=$(cat  $TMPDIR/table0 |sort -t '|' -k 4n | grep -v '#+' | head -2 | tail -1  | sed -e 's/^\#|\s*\S*\s*|\s*\(\S*\)\s.*/\1/')
fi


#[ -n "${TABLE0}" -a -z "${NHIER}" ] && {
#    echo '#'
#    echo '#######################'
    echo '# When --table0 you have to specify --nhier N [M..]'
#    echo '#'
#    exit 0
#}

((1)) && {
    echo "# ***** Phones list for NHIER='$NHIER'"
    mysql --batch --skip-column-names --raw $AP -e  "
        SELECT
            -- body.ad_id,
            phonen,
            '${REGION}',
            MAX(body.idate),
            CONCAT('\"aviso nhiers:',nhier,', ads:',count(distinct body.ad_id),'\"' )
        FROM
            synd
        LEFT JOIN phones ON
            synd.ad_id = phones.ad_id
        LEFT JOIN body ON
            synd.ad_id = body.ad_id
        ${NHIER:+WHERE
            nhier IN (${NHIER}) }
        GROUP BY 
            phonen
        ORDER BY
            synd_id
    "
    echo "# ***** Phones list for NHIER='$NHIER'"

}

exit 

__END__

=pod
=head1 NAME

phones-tread.sh - Store phones to sms table.

=head1 SYNOPSIS

phones-tread.sh [OPTIONS] [kiev|odessa|dnepr]

=head1 OPTIONS

=over 4

=item B<--help> | B<-h>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--table0>

Show main data table for analyse

=item B<--nhier [I [,J,...]] >

Build phones list for specified NHIER (number of rubrics ). Or for all

=back

=cut
