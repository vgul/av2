#!/bin/bash

set -u

EFFSCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
MY_PATH="$(dirname "${EFFSCRIPT}")/"
APP0="$(basename $EFFSCRIPT)"

VALID_DOMENS='kiev|dp|od'
TMPDIR="/tmp/$APP0-$$-$RANDOM"
trap "[ -d \"${TMPDIR}\" ] && : echo rm -rf \"${TMPDIR}\" && rm -rf \"${TMPDIR}\" " EXIT 
mkdir -p $TMPDIR

ATOM_USER=box711@mail.ru
ATOM_PASS=vladA17
SUBJECT=Zvonar

TEST_PHONE="+380954800001"
AP_SMS='-u root -D av2_clients '
TABLE=sms

SEND_URL='http://atompark.com/members/sms/xml.php'
FILETEXT=
DO=
COUNT=
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
        --count)
            COUNT=$2
            shift 2
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


echo mysql ${AP_SMS} -e "'select ... from sms limit 1'"
mysql ${AP_SMS} -e "
    select 
        IF( count(*)=1, CONCAT('p',phone), count(*) ) as cnt_ph,
        MAX(sent),
        MIN(sent),
        status,
        region 
    FROM sms 
    GROUP BY status, region "

[ -z "${DO}" ] && {
    echo -n "Will send from $TEST_PHONE. Specify --do option (--count N too )"
}

if ((1)); then
    echo
    while [ 0 ]; do
        read -p "Proceed send process ? [Yes/n]: " CHOICE
        shopt -s nocasematch
        case $CHOICE in
            y|yes)
                #SOME=1
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
                (status IS NULL
                AND credits IS NULL
                AND amount IS NULL)
                OR
                status=-3
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
        PH=$TEST_PHONE
        REGION=${REGION:-kiev}
        echo "PH=$PH REGION=$REGION "
    fi


    REGION_DOMEN=$(echo $REGION | sed -e 's/^dnepr$/dp/' -e 's/^odessa$/od/' )
    echo "$REGION_DOMEN" | grep -qP "^($VALID_DOMENS)$"
    (($?)) && {
        echo "Skiped. None of ${VALID_DOMENS} valid domens"
        exit
    }
    printf -v BODY "$TEMPLATE" $REGION_DOMEN
    #echo "$PH Text: $BODY"
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

        [ -n "${COUNT}" ] && ((SENT_CNT>=COUNT)) && {
            echo "Count value $COUNT reached."
            break
        }
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

=item B<--count N>

How many sms to send

=item B<--opt2 [I [,J,...]] >

Describe

=back

=cut
