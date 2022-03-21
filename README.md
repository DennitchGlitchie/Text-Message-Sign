This project attempts to utilize a raspberry pi as an SMS access point (through Twilio) to control an LED matrix

(1) Gathering Hardware:
- Raspberry Pi 4 Model B
- SD Card
- Pro-Lite PL-M2014R

(2) Setting up Raspberry Pi as a Web Server for Twilio Access
- DietPi Image https://dietpi.com/docs/install/
- Setting up automatic wifi by editting the config file https://dietpi.com/phpbb/viewtopic.php?p=9#p9
  - Open dietpi-wifi.txt and open it with wordpad
  - Change aWIFI_SSID[0]='MySSID' and aWIFI_KEY[0]='MyWifiKey'
  - Don't forget to also enable automatic wifi in another file
  - Probably should come back and put in the phone's tether wifi(s) for automatic connection
- Setting up ssh key for raspberry pi from laptop: ssh -i TextMessageSign root@10.0.0.128
  - using the diet-config command to change ssh to OpenSSH and not Dropbear
  - Use ssh-keygen to generate a key with custom name and adding the .pub file to ~/.ssh/authorized_keys (remember to respond "Yes")
  - This process I used a thumb drive to transfer and mount the file (mkdir /media/usb; sudo mount -o umask=0,uid=111,gid=33 /dev/sdc1 /media/usb; lsblk)
- Setting up ssh key for cloud_vm from raspberry pi: ssh -i ~/.ssh/cloud_vm garges@34.127.85.102
  - Use ssh-keygen on raspberry pi to generate a key with custom name and adding .pub file to ~/.ssh/authorized_keys (remember to respond "Yes")
- Setting up reverse tunnelling between cloud vm and raspberry pi
  - Testing out the reverse tunnel ssh -N -R 0.0.0.0:6001:localhost:22 -i ~/.ssh/Cloud_vm garges@34.127.85.102 and follow with ssh -p 6001 root@localhost
  - Using port 6001 here because there was a conflict with the reverse tunnelling known_hosts with the owncloud_pi 
  - Creating tunnel.sh with correct permissions (chmod 777 tunnel.sh) and adding in ssh -N -R 0.0.0.0:6001:localhost:22 -i ~/.ssh/cloud_vm garges@34.127.85.102
  - crontab -e to open the cron tab and */1 * * * * ~/tunnel.sh > tunnel.log 2>&1
- Installing Web Server for CGI-bin use 
  - wget https://acme.com/software/thttpd/thttpd-2.29.tar.gz
  - tar xvf ./thttpd-2.29.tar.gz (unzip package)
  - cd into the directory
  - ./configure (can add a prefix for the directories)
  - make; make install (gives an error with group www - doesn't seem to be significant)
  - sudo apt install nvi
  - mkdir www/index.html (this is the static site)
  - mkdir www/cgi-bin
  - sudo nano myfile.sh; #!/bin/sh; echo "Your query string was: $QUERY_STRING"
  - chmod a+x
  - thttpd -C /etc/thttpd.conf (can add -D to run this in the background)
  - -d specifies the directory to serve files from, -p specifies the port to listen on, -c specifies the URL pattern for CGI scripts that should be executed instead of served directly
  - Doing systemd to have the webserver start automatically
  - changing configuration of .sh scripts for the cgi-bin (saw this in a tutorial someplace)
  - Getting the correct script to extract the text message
  - Static site URL: http://34.127.85.102:6082/
  - Andrew and I worked on getting the images to show up and we needed executible permisions (by other) in the file directory. Also, thttpd has a error when you give the images executibles so they gotta be read (write doesn't matter but it CAN'T be executible). 
  - drw-r--r-x 2 root root     4096 Dec 18 02:56 .
  - -rw-r--r-- 1 root root  1090691 Dec 18 02:56 IMG-0171.jpg


(2.5) Setting up Public Access with port forwarding and cloud vm 
- configure the "trusted_domains" setting in config/config.php: sudo nano /var/www/owncloud/config/config.php
  - 4 => '34.127.85.102', 
- Creating automated script so that the reverse tunnel and port translation are automatically done
  - creating tunnel.sh script from tutorial with correct permissions
  - ssh -N -R 0.0.0.0:6001:localhost:22 -R 0.0.0.0:6081:localhost:80 -i ~/.ssh/cloud_vm garges@34.127.85.102
  - /etc/ssh/sshd_config "gateway ports" this is the file that was changed on the cloud vm "GatewayPorts clientspecified"
  - crontab -e to open the cron tab
  - */1 * * * * ~/tunnel.sh > tunnel.log 2>&1
- Using netstat -nlpt to confirm that we have the right accessability with the ports (I am unsure to what command I used for this):
  - tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      792/lighttpd        
  - tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      636/sshd: /usr/sbin 
  - tcp6       0      0 :::80                   :::*                    LISTEN      1569/thttpd 
- Need to start the web server to see that the port 80 is listening
- thttpd -C /etc/thttpd.conf
- http://34.127.85.102:6082/
- http://34.127.85.102:6082/cgi-bin/myfile.sh
- https://www.2daygeek.com/linux-create-systemd-service-unit-file/
- 

Andrew suggests translating port 80 to port 80 like we did with owncloud
mkdir www/cgi-bin with file gpio
on private network: http://Rasppi/cgi-bin/gpio will run the script like he said
don't forget about permissions to run the files 


(3) Setting up Twilio as an access point 
- Creating number - 12488461690
- Setting up and configuring webhook

(4) Getting code for the sign to work:
https://github.com/qartis/misc/blob/master/pl-m2014r-serial.c
it basically just outputs a header and then writes whatever text you give it as a command line argument out to the sign
here's an example of the protocol, that explains how to write messages in different colors, etc
http://wearcam.org/ece385/prolite_documentation/ProliteProtocol.html
wget https://raw.githubusercontent.com/qartis/misc/master/pl-m2014r-serial.c

Conversation with Andrew:
Also, just a clarifying statement regarding the port forwarding/listening: 

On my owncloud pi, I am running the following in crontab 
ssh -N -R 0.0.0.0:6000:localhost:22 -R 0.0.0.0:6080:localhost:80 -i ~/.ssh/cloud_vm garges@34.127.85.102
This means that 6000 on any wildcard IP will be translated to port 22 and 6080 on any wilcard IP will be translated to port 80.
Port 22 is the default SSH server because that's how we do the reverse tunneling right? Port 80 and 6080 are just ports that we picked that are non default correct?

Andrew Fuller, Yesterday 6:00 PM
port 80 is the default port for http traffic
port 22 and 80 are the actual ports that the sshd and httpd servers are listening on,
and those -R forwarding specifications cause your_vm:6000 to tunnel through that SSH connection and end up hitting port 22 on your pi,
and same thing for 6080 -> 80
if you wanted to, you could also forward port 80 -> port 80
with one caveat: in order to listen on port 80, you need to be root
any port below 1024
so this wouldn't work:
ssh garges@vm -R 80:localhost:80
because on the vm, user "garges" isn't allowed to bind to port 80
but this would work:
ssh root@vm -R 80:localhost:80

Using journalctl to see the logs; adding -f will show ongoing logs 

root@DietPi:~/www/cgi-bin# cat /etc/thttpd.conf 
dir=/root/www
cgipat=**.sh
#cgipat=/cgi-bin/*

Andrew 1on1 2022 01 31:
- lsusb to list the device
- wget https://raw.githubusercontent.com/qartis/misc/master/pl-m2014r-serial.c
- dmesg to see which ttyUSBX was attached
- stty -F /dev/ttyUSB0 to see the current serial settings 
- stty -F /dev/ttyUSB0 -icanon for exampel to turn things explicitly off. 
- cc pl-m2014r-serial.c  to compile to a.out
- using cat /dev/ttyUSB0 | xxd -c 1 to monitor serial port
- 2400 4800 9600 19200 38400 57600 115200
- stty -F /dev/ttyUSB0 9600; sleep 1; echo -en "<ID01>\r\n" > /dev/ttyUSB0; sleep 1; echo -en "<ID01>abc\r\n" > /dev/ttyUSB0
- stty -F /dev/ttyUSB0 9600 to set the baud rate

root@DietPi:~/www# stty -F /dev/ttyUSB0 sane  -echo -icanon -icrnl -inlcr -ocrnl -onlcr
root@DietPi:~/www# stty -F /dev/ttyUSB0
speed 9600 baud; line = 0;
min = 1; time = 0;
-icrnl
-onlcr
-icanon -echo
  
Post Rave Twilio Texting Service Bringup
- Reverse tunnel ssh -p 6001 root@localhost
- had to manually run thttpd -C /etc/thttpd.conf
- Using netstat -nlpt to verify that it's working
- Check static site http://34.127.85.102:6082/
- Checking that manual webhook shows up in /var/tmp/log.log http://34.127.85.102:6082/cgi-bin/myfile.sh
- On Twilio Develop -> Phone Numbers -> Manage -> Active Numbers to edit phone number
- Set "A Message Comes in" Webhook to be http://34.127.85.102:6082/cgi-bin/myfile.sh GET
- Open up two terminals: "cat /dev/ttyUSB0 | xxd -c 1" to monitor serial port" and "stty -F /dev/ttyUSB0 9600; sleep 1; echo -en "<ID01>\r\n" > /dev/ttyUSB0; sleep 1; echo -en "<ID01>abc\r\n" > /dev/ttyUSB0" while shorting TX and RX. I have verified that the USB -> DB9 is good and the DB9 -> CAT6 is good
- Baud Rates: 2400 4800 9600 19200 38400 57600 115200
- stty -F /dev/ttyUSB0 sane  -echo -icanon -icrnl -inlcr -ocrnl -onlcr 115200
- echo -en "<ID00>\r\n" > /dev/ttyUSB0; sleep 1; echo -en "<ID00><PA>abc\r\n" > /dev/ttyUSB0
- echo -en "<ID01>\r\n" > /dev/ttyUSB0; sleep 1; echo -en "<ID01><PA>abc\r\n" > /dev/ttyUSB0

  
Getting the Sign to work Wednesday March 2nd: 
- stty sane -echo -icanon -icrnl -inlcr -ocrnl -onlcr 9600 < /dev/ttyUSB0
- echo -ne "<ID00>\r\n" > /dev/ttyUSB0; sleep 1; echo -ne "<ID00><PA>xxxxxxxxxx\r\n" > /dev/ttyUSB0
- echo -ne "<ID00><PA>xxxxxxxxxx\r\n" > /dev/ttyUSB0
- chmod 777 dev/ttyUSB0

  
  Andrew 1on1 March 17th:
  sudovi (to change the sudoers file in a safe way) with the goal to specifically allow `nobody` run write2sign.sh with no password
  # Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) ALL
nobody ALL=(ALL) NOPASSWD: /root/write2sign.sh

Andrew 1on1 March 21st: 
  +[Unit]
+Description=Tiny HTTP Daemon
+
+[Service]
+PIDFile=/run/thttpd.pid
+ExecStart=/usr/sbin/thttpd -D -C /etc/thttpd.conf
+Restart=always
+
+[Install]
+WantedBy=multi-user.target
