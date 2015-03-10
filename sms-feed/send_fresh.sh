#!/bin/bash

set -u

AP_SMS=' -u root -D aviso2 '
REGION='dnepr'
RUBRICS="kv_kup kv_sni ko_kup ko_sni do_kup do_sni"
#RUBRICS="ko_sni"

function yes_no {
    local TEXT="${1:-}"
    YES=
    while [ 0 ]; do
        read -p "${TEXT}" CHOICE
        shopt -s nocasematch
        case $CHOICE in
            y|ye|yes|1)
                YES=1
                break
                ;;
            n|no|0)
                YES=0
                break
                ;;
        esac
        shopt -u nocasematch
    done
    return $YES
}

for RUBR in ${RUBRICS}; do
    P_FILE="${REGION}_${RUBR}.phones"
    mysql -B -N ${AP_SMS} -e "select distinct phones_to_page from ${REGION} where type='${RUBR}' " > "${P_FILE}"
    wc -l ${P_FILE}
done

echo
for RUBR in ${RUBRICS}; do
    P_FILE="${REGION}_${RUBR}.phones"
    yes_no "$(wc -l ${P_FILE}). Store to send ? [yes/no]: "

    (($?)) && {        
        cat "${P_FILE}" | \
        store-phone-to-send.sh --region ${REGION} --source "fresh. aviso ${REGION} ${RUBR}"
    }
done



exit 0
__END__

cat Trics > send_kiev
vim send_kiev 
mysql -B  -N    -u root -D aviso2 -e "select distinct phones_to_page from kiev where type='kv_kup' " > send_kiev 
vim send_kiev 
cat send_kiev | head -1
cat send_kiev | head -1 | store-phone-to-send.sh --region kiev --source 'aviso kiev nhier:1 kv_kup'
cat send_kiev | head -1 | bash ./store-phone-to-send.sh --region kiev --source 'aviso kiev nhier:1 kv_kup'
cat send_kiev | bash ./store-phone-to-send.sh --region kiev --source 'aviso kiev nhier:1 kv_kup'
mysql -B  -N    -u root -D aviso2 -e "select distinct phones_to_page from kiev where type='kv_kup' " > send_kiev 
cat send_kiev | bash ./store-phone-to-send.sh --region kiev --source 'aviso kiev nhier:1 kv_kup'
history | grep send_kie
history | grep send_kie > send.sh
