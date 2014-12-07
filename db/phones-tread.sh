#!/bin/bash

set -u

AP="$MAV2SOURCE"
REGION=kiev

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
            # Non option argument
            break # Finish for loop
            ;;
    esac
done


DEMO=
[ -z "${NHIER}" ] && {
    DEMO=1
}

((TABLE0)) && {
    echo '# n_ph  - Nuber of phones'
    echo '# n_ad  - count(distinct body.ad_id) - number of adverts'
    echo '# nhier - How many rubrics for phones group' 
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
" | sed -e 's/^/#/'

}

[ -n "${TABLE0}" -a -z "${NHIER}" ] && {
    echo '#'
    echo '#######################'
    echo '# When --table0 you have to specify --nhier N [M..]'
    echo '#'
    exit 0
}



((1)) && {

    echo "# ***** Phones list for NHIER='$NHIER'"
    mysql --batch --skip-column-names --raw $AP -e  "
        SELECT
            -- body.ad_id,
            phonen,
            MAX(body.idate),
            CONCAT('\"aviso ${REGION}. nhiers:',nhier,', ads:',count(distinct body.ad_id),'\"' )
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
