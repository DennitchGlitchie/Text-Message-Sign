root@DietPi:~# cat write2sign.sh 
#!/bin/bash

MYMESSAGE=$1
stty sane -echo -icanon -icrnl -inlcr -ocrnl -onlcr 9600 -F /dev/ttyUSB0
echo -ne "\r\n" > /dev/ttyUSB0
sleep 1
echo -ne "<ID00><PA>$MYMESSAGE   \r\n" > /dev/ttyUSB0
