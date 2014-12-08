#!/bin/bash

set -u

AP_SMS='-u root -D av2_clients'


VALID_REGIONS='kiev|dnepr|odessa'
STDIN=
PHONE=
SCRAPED=
COMMENT=
ILLEGAL=
TABLE=sms
[ ! -t 0 ] && STDIN=1

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

        --comment|-c)
            COMMENT=1
            shift
            ;;

        --illegal|-i)
            ILLEGAL=1
            shift
            ;;

        --table|-t)
            TABLE=$1
            shift 2
            ;;

        --)
            # Rest of command line arguments are non option arguments
            shift # Discard separator from list of arguments
            continue
            #break # Finish for loop
            ;;
        -*)
            echo "Unknown option: $1" >&2
            pod2usage --verbose 1 --output ">&2" "$0"
            exit 2
            ;;

        *)
            echo "Not expected arguments: $1" >&2
            pod2usage --verbose 1 --output ">&2" "$0"
            exit 2
            # finish parsing options
            #break
            ;;
    esac
done


function insert {
    local PHONE=$1
    local REGION=${2}
    local SCRAPED=${3:-}
    local SOURCE="${4:-}"
    #echo "Insert: $PHONE SCRAPED=$SCRAPED SOURCE=$SOURCE"
    mysql $AP_SMS -e "
        INSERT INTO ${TABLE} SET 
            phone=${PHONE}
            ,region='${REGION}' 
            ,stored=NOW()
            ${SCRAPED:+,scraped='${SCRAPED}'}
            ${SOURCE:+,source='${SOURCE}'}
    "
}

((STDIN)) && {
    COUNT=0
    ILLEGAL_COUNT=0
    while read -r LINE ; do
        echo $LINE | grep -qP  '^\s*#'
        [ $? == 0  ] && {
            ((COMMENT)) && echo "$LINE" 
            continue
        }

        SPACES="${LINE//[^[:space:]]/}"


        #echo ":${SPACES}:"
        case "${#SPACES}" in

            0)
                echo "You have to specify PHONE REGION"
                exit 0
                #echo 1
                PHONE=${LINE%%[[:space:]]*}
                ;;
            1)
                #echo 1
                PHONE=${LINE%%[[:space:]]*}
                #echo PHONE $PHONE
                TMP=${LINE/${PHONE}[[:space:]]/}
                REGION=${TMP%%[[:space:]]*}
                ;;

            2)
                #echo echo 2
                PHONE=${LINE%%[[:space:]]*}
                #echo PHONE $PHONE
                TMP=${LINE/${PHONE}[[:space:]]/}
                REGION=${TMP%%[[:space:]]*}
                #echo "TMP :${TMP}:"
                SCRAPED=${TMP#*[[:space:]]}
                #echo SCRAPED $SCRAPED
                ;;
            *)
                #echo echo More
                PHONE=${LINE%%[[:space:]]*}
                TMP=${LINE/${PHONE}[[:space:]]/}
                REGION=${TMP%%[[:space:]]*}
                TMP=${TMP#*[[:space:]]}
                SCRAPED=${TMP%%[[:space:]]*}
                SOURCE="${TMP#*[[:space:]]}"
                ;;
        esac

        echo "$REGION" | grep -qP "^($VALID_REGIONS)$"
        (($?)) && {
            echo "Skiped. None of ${VALID_REGIONS}"
            exit
        }
        

        echo $PHONE | grep -qP '^(50|66|95|99|67|68|96|97|98|91|92|94|93|63)'
        [ $? != 0 -o ${#PHONE} != 9 ] && {
            ((ILLEGAL)) && echo "Illegal mobile number: $PHONE length ${#PHONE}"
            ((ILLEGAL_COUNT++))
            continue
        }
        ((COUNT++))
        insert $PHONE $REGION $SCRAPED "$SOURCE"
    done
    echo "${COUNT} count"
    ((ILLEGAL_COUNT)) && echo "${ILLEGAL_COUNT} illegal count"
}

exit 

=pod
=head1 NAME

store-to-send.sh - Store phones to sms table.

=head1 SYNOPSIS

store-to-send.sh PHONE kiev|dnepr|odessa [SCRAPED_DATA] [[COMMENT]]

or

echo PHONE | store-to-send.sh [--comment | -c ]

echo PHONE REGION

echo PHONE REGION SCRAPED_DATA | store-to-send.sh [--comment | -c ]

echo PHONE REGION SCRAPED_DATA   COM MEN T   | store-to-send.sh [--comment | -c ] [--illegal | -i ]

=head1 OPTIONS

=over 4

=item B<--illegal> | B<-i>

Show illegal mobile phones.

=item B<--comment> | B<-c>

Show incomig comments.

=back

=cut
