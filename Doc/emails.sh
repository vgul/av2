

ssh vvg@grex.org '
A=zvonar.kiev@ya.ru ; 
echo -e "$A\n$(date)" | mail -s "Aviso2 project. Test through $A"  $A ;
echo "sent for $A" ;

A=zvonar.dp@ya.ru ; 
echo -e "$A\n$(date)" | mail -s "Aviso2 project. Test through $A"  $A ;
echo "sent for $A" ;

A=zvonar-kiev@ukr.net ; 
echo -e "$A\n$(date)" | mail -s "Aviso2 project. Test through $A"  $A ;
echo "sent for $A" ;

A=zvonar-dnepr@ukr.net ; 
echo -e "$A\n$(date)" | mail -s "Aviso2 project. Test through $A"  $A ;
echo "sent for $A" ;

A=v.hotmail@ya.ru ; 
echo -e "$A\n$(date)" | mail -s "Aviso2 project. Test through $A"  $A ;
echo "sent for $A" ;

echo End
'




