#!/bin/bash

set -u

EFFSCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
MY_PATH="$(dirname "${EFFSCRIPT}")/"
APP0="$(basename $EFFSCRIPT)"

TMPDIR="/tmp/$APP0-$$-$RANDOM"
trap "[ -d \"${TMPDIR}\" ] && : echo rm -rf \"${TMPDIR}\" && rm -rf \"${TMPDIR}\" " EXIT 
mkdir -p $TMPDIR

ATOM_USER=box711@mail.ru
ATOM_PASS=vladA17
SUBJECT=Zvonar


AP_SMS='-u root -D av2_clients '
TABLE=sms

SEND_URL='http://atompark.com/members/sms/xml.php'
FILETEXT=
DO=
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

        --do)
            DO=1
            shift
            ;;

        #--filetext)
        #    FILETEXT=$2
        #    shift 2
        #    ;;

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
            FILETEXT=$1
            # Non option argument
            break # Finish for loop
            ;;
    esac
done
#TEXT=
#    echo 'Text [ $0 filename ] not specified'
#    exit 1
#}

#FILE="${MY_PATH}/Textes/${FILETEXT}"
#echo $FILE
#[ ! -f "${FILE}" ] && {
#    echo "Not found '$TEXT'"
#    exit 1
#}
#echo "I take text from '$FILE'"

#TEMPLATE="Kvartiry, Doma, Uchastki, Ofisy.&#10;Vybor objectov.&#10;Sdelki bez komissii.&#10;1e ruki.&#10;Kuplju-Prodam-Sdam-Snimu&#10;http://zvonar.%s.ua"
TEMPLATE="Квартиры,Дома,Участки,Офисы&#10;Без комиссии&#10;1е руки&#10;http://zvonar.%s.ua"

EXIT=0
trap exiting SIGINT
exiting() { echo "Ctrl-C trapped, will not restart utorrent" ; EXIT=1;}
SENT_CNT=0
while [ $EXIT -eq 0 ] ; do
    if ((DO)); then
        DATA=$(mysql -B -N $AP_SMS -e "
            SELECT 
                CONCAT(phone,' ',region,' ',stored)
            FROM ${TABLE} 
            WHERE 
                status IS NULL
                AND credits IS NULL
                AND amount IS NULL
            ORDER BY 
                stored ASC
            limit 1
        ")
        [ -z "${DATA}" ] && {
            echo Finished. Sent $SENT_CNT.
            exit 0
        }
        #echo $DATA
        PH0="${DATA%%[[:space:]]*}"
        TMP="${DATA/$PH0[[:space:]]/}"
        #echo TMP: $TMP
        REGION="${TMP%%[[:space:]]*}"
        STORED=${TMP#*[[:space:]]}
        #echo PH0=$PH0 
        #echo REGION=$REGION
        #echo STORED=$STORED
        PH="+380${PH0}"
    else
        PH='+380954800001'
        REGION=kiev
        echo "PH=$PH REGION=$REGION "
    fi


    printf -v BODY "$TEMPLATE" $REGION
    #echo "Text: $BODY"
    XML="
    <SMS>
        <operations>
        <operation>SEND</operation>
        </operations>
        <authentification>
        <username>${ATOM_USER}</username>
        <password>${ATOM_PASS}</password>
        </authentification>
        <message>
        <sender>${SUBJECT}</sender>
        <text>${BODY}</text>
        </message>
        <numbers>
        <number>${PH}</number>
        </numbers>
    </SMS>"

    OUT="$(echo $XML | curl -s  --data "@-" -X POST "${SEND_URL}" )" 
                                                            #> $TMPDIR/answer
#    OUT="
#<?xml version="1.0" encoding="UTF-8"?>
#<RESPONSE>
#<status>1</status>
#<credits>0.3902</credits>
#<amount>0.16</amount>
#<currency>UAH</currency>
#</RESPONSE>
#"
    #echo "${OUT}"
    STATUS=$(   echo "$OUT" | grep status   | sed -e 's/<\/\?status>//g' )
    CREDITS=$(  echo "$OUT" | grep credit   | sed -e 's/<\/\?credits>//g' )
    AMOUNT=$(   echo "$OUT" | grep amount   | sed -e 's/<\/\?amount>//g' )
    CURRENCY=$( echo "$OUT" | grep currency | sed -e 's/<\/\?currency>//g' )

    #echo STATUS $STATUS
    #echo CREDITS $CREDITS
    #echo CURRENCY $CURRENCY


    if ((DO)); then 
        RES="$(mysql -B -N $AP_SMS -e "
            UPDATE ${TABLE} set
               stored=stored,
               sent=NOW(),
               status=$STATUS,
               credits=$CREDITS,
               amount=$AMOUNT,
               currency='${CURRENCY}'
            WHERE
                phone=$PH0
                AND stored='${STORED}'
                AND region='${REGION}'
        ; select row_count() ")"
        ((SENT_CNT+=RES))
        echo "$SENT_CNT [$STATUS] PH=$PH REGION=$REGION " CREDITS=$CREDITS AMOUNT=$AMOUNT
    else
        echo 'Test invoke finished'
        break
    fi
done

echo "out of loop"

exit 0

__END__

=pod
=head1 NAME

sender.sh - Send sms to atom

=head1 SYNOPSIS

sender.sh

=head1 OPTIONS

=over 4

=item B<--help> | B<-h>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--opt1>

Describe

=item B<--opt2 [I [,J,...]] >

Describe

=back

=cut
