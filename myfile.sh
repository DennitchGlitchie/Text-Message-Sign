root@DietPi:~/www/cgi-bin# cat myfile.sh 
#!/bin/bash
echo -en "Status: 200 OK\r\n"
echo -en "Content-Type: text/plain\r\n"
echo -en "\r\n" 

# Logging Information for development
echo "Page was accessed :" $(date) >> /var/tmp/log.log
echo "The Request Method was :" >> /var/tmp/log.log
echo "$REQUEST_METHOD" >> /var/tmp/log.log
echo "The Query String is :" >> /var/tmp/log.log
echo "$QUERY_STRING" >> /var/tmp/log.log

# Parsing the Texting Message Data
IFS="&"
set -- $QUERY_STRING
echo "The Body String is: " >> /var/tmp/log.log
echo ${11} >> /var/tmp/log.log #This is the SMS body

IFS="="
set -- ${11}

echo "The Text Message sent was: " >> /var/tmp/log.log
echo $2 | sed 's/+/ /g' >> /var/tmp/log.log

MYMESSAGE=$(echo "$2" | sed 's/+/ /g')

# Since the webserver will run this as "nobody", sudo permissions are changed with the write2sign.sh file
sudo /root/write2sign.sh "$MYMESSAGE"
