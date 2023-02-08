This project utilizes a raspberry pi as an SMS access point (with Twilio) to control text on an LED matrix sign

(1) Gathering Hardware:
- Raspberry Pi 4 Model B (with keyboard and display for setup)
- SD Card
- Pro-Lite PL-M2014R LED Matrix Sign
- Electrical Hookups: (Fuse taps, voltage converters, what else??)
- Mounting Brackets with Velcrow
- Switch: https://www.jimellisvwparts.com/products/Switch/11484389/1K0927122AREH.html

(2) Setting up Raspberry Pi for reliable/rebootable SSH utilizinge auto SSH and systemd
- DietPi Image https://dietpi.com/docs/install/
- Setting up automatic wifi by editting the config file https://dietpi.com/phpbb/viewtopic.php?p=9#p9
  - Open dietpi-wifi.txt and open it with wordpad
  - Change aWIFI_SSID[0]='MySSID' and aWIFI_KEY[0]='MyWifiKey' (Don't forget to also enable automatic wifi in another file)
  - Adding my cell phone's network "Tether" as primary wifi source (along with home wifi for setup). Can also do this in the diet-config
- Setting up ssh key for raspberry pi from laptop: 
  - using the diet-config command to change ssh to OpenSSH and not Dropbear
  - identifying the IP Address of the raspberry pi on the home network with hostname -I
  - Use ssh-keygen to generate a key with custom name (TextMessageSign) and adding the .pub file to ~/.ssh/authorized_keys (remember to respond "yes")
  - Getting the public key to the raspberry pi with a flashdrive (mkdir /media/usb; sudo mount -o umask=0,uid=111,gid=33 /dev/sdc1 /media/usb; lsblk)
  - ssh -i TextMessageSign root@10.0.0.128 
- Setting up ssh key for cloud_vm from raspberry pi: 
  - This assumes I already have a cloud_vm set up. See my Owncloud project for details on how to set up cloud_vm
  - Use ssh-keygen on raspberry pi to generate a key with custom name and adding .pub file to ~/.ssh/authorized_keys (remember to respond "yes")
  - ssh -i ~/.ssh/cloud_vm garges@34.127.85.102
- Setting up reverse tunnelling between cloud vm and raspberry pi
  - Veryifying the reverse tunnel ssh -N -R 0.0.0.0:6001:localhost:22 -i ~/.ssh/Cloud_vm garges@34.127.85.102 and follow with ssh -p 6001 root@localhost
  - Using port 6001 here because there was a conflict with the reverse tunnelling known_hosts with the owncloud_pi which uses 6000. 
  - The next project will likely use 6002 
  - In the past I have used crontab -e to run a tunnel script (crontab -e to open the cron tab and */1 * * * * ~/tunnel.sh > tunnel.log 2>&1) which is not a good solution
  - Best way to do it is to set up an autossh systemd service
    - sudo apt-get install autossh
    - Created a new service file /etc/systemd/system/autossh.service (see autossh.service)
    - sudo systemctl daemon-reload 
    - sudo systemctl start custom.service
    - journalctl will give the logs
- /etc/ssh/sshd_config "gateway ports" this is the file that was changed on the cloud vm "GatewayPorts clientspecified" (keeping this note here even though this file is not changed)
- Remember: Port 22 is the default SSH server, port 80 is the default http traffice server. 6001 on any wildcard IP will be translated to port 22 and 6081 on any wilcard IP will be translated to port 80. You need to be root on any port below 1024. ssh garges@vm -R 80:localhost:80 (would NOT work) while ssh root@vm -R 80:localhost:80 (would work) 
- SSH into cloud vm from laptop: ssh -i ~/.ssh/cloud_vm garges@34.127.85.102
- SSH into raspberry pi from cloud vm: ssh -p 6001 root@localhost

(3) Setting up Twilio Number and Access 
- Creating number - (12488461690)
- On Twilio Develop -> Phone Numbers -> Manage -> Active Numbers to edit phone number to put the following:
- Set "A Message Comes in" Webhook to be http://34.127.85.102:6081/cgi-bin/myfile.sh GET

(3.5) Automated Text Service
- I attempted to use this phone number to send "automated" responses
- Really I just manually sent responses to the incoming messages
- I'm not sure if this conflicts with the incoming webhook
- I will have to document how I do this in the future

(4) Setting up automatic Webserver on Raspberry pi: 
- Downloading thttpd (tiny http daemon)
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
- Using systemd to automatically start the webserver
  - Created a new service file /etc/systemd/system/thttpd.service (see thttpd.service)
  - sudo systemctl daemon-reload 
  - sudo systemctl start thttpd.service
  - journalctl will give the logs
- Using netstat -nlpt to confirm that we have the right accessability with the ports (I am unsure to what command I used for this):
  - tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      792/lighttpd        
  - tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      636/sshd: /usr/sbin 
  - tcp6       0      0 :::80                   :::*                    LISTEN      1569/thttpd 
- Edditing the /etc/thttpd.conf file to indicate cgi-bin nomenclature: see thttpd.conf file
- thttpd -C /etc/thttpd.conf
- See ~/www/cgi-bins/myfile.sh
- See ~/www/index.html and ~/www/index.css
- See ~/write2sign.sh
  - This needs to have some sudo permissions change since this will be run by user "nobody". Need to allow sudo access to JUST this file.
  - sudo visudo (to change the sudoers file in a safe way) with the goal to specifically allow `nobody` run write2sign.sh with no password
    "#### Allow members of group sudo to execute any command
    %sudo   ALL=(ALL:ALL) ALL
    nobody ALL=(ALL) NOPASSWD: /root/write2sign.sh

(4.5) Static Site
- Static site URL: http://34.127.85.102:6081/
- Images need the right kind of permissions. thttpd will give an error when they are executible so the images have to be read (write irrelevant) and NOT executible
  - drw-r--r-x 2 root root     4096 Dec 18 02:56 .
  - -rw-r--r-- 1 root root  1090691 Dec 18 02:56 IMG-0171.jpg
- See ~/www/cgi-bins/myfile.sh
- See ~/www/index.html and ~/www/index.css

(5) Setting up Sign Communication and webhook 
- http://wearcam.org/ece385/prolite_documentation/ProliteProtocol.html
- wget https://raw.githubusercontent.com/qartis/misc/master/pl-m2014r-serial.c (I didn't end up using this but saved it in my files)
- See ~/write2sign.sh
  - This needs to have some sudo permissions change since this will be run by user "nobody". Need to allow sudo access to JUST this file.
  - sudo visudo (to change the sudoers file in a safe way) with the goal to specifically allow `nobody` run write2sign.sh with no password
    # Allow members of group sudo to execute any command
    %sudo   ALL=(ALL:ALL) ALL
    nobody ALL=(ALL) NOPASSWD: /root/write2sign.sh
- Ultimately, the way to write to the sign is: 
  - stty sane -echo -icanon -icrnl -inlcr -ocrnl -onlcr 9600 -F /dev/ttyUSB0
  - echo -ne "\r\n" > /dev/ttyUSB0
  - sleep 1
  - echo -ne "<ID00><PA>$MYMESSAGE   \r\n" > /dev/ttyUSB0
- Created a new service file /etc/systemd/system/custom.service (see custom.service) to wipe the sign on startup
  
(5.5) Debugging Tips for Sign Communication
- lsusb to list the device
- dmesg to see which ttyUSBX was attached
- stty -F /dev/ttyUSB0 to see the current serial settings 
- stty -F /dev/ttyUSB0 -icanon for exampel to turn things explicitly off. 
- cc pl-m2014r-serial.c  to compile to a.out
- using cat /dev/ttyUSB0 | xxd -c 1 to monitor serial port
- Baud ratest that we tried: 2400 4800 9600 19200 38400 57600 115200
- stty -F /dev/ttyUSB0 9600; sleep 1; echo -en "<ID01>\r\n" > /dev/ttyUSB0; sleep 1; echo -en "<ID01>abc\r\n" > /dev/ttyUSB0
- stty -F /dev/ttyUSB0 9600 to set the baud rate
https://github.com/qartis/misc/blob/master/pl-m2014r-serial.c
it basically just outputs a header and then writes whatever text you give it as a command line argument out to the sign
here's an example of the protocol, that explains how to write messages in different colors, etc
http://wearcam.org/ece385/prolite_documentation/ProliteProtocol.html
wget https://raw.githubusercontent.com/qartis/misc/master/pl-m2014r-serial.c
root@DietPi:~/www# stty -F /dev/ttyUSB0 sane  -echo -icanon -icrnl -inlcr -ocrnl -onlcr
root@DietPi:~/www# stty -F /dev/ttyUSB0
speed 9600 baud; line = 0;
min = 1; time = 0;
-icrnl
-onlcr
-icanon -echo
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

(6) Mounting of sign into car
- Fuse Tap: https://www.amazon.com/dp/B0827L4HH9?psc=1&ref=ppx_yo2ov_dt_b_product_details
- Emergeny Jump Start:
- 5V Converter
- 9V Converter
- inline toggle switch

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Rough Notes:
   swapon -s
  492  vim /etc/fstab
  493  swapoff
  494  swapoff /var/swap
  495  swapoff -a
  496  swapon -s
  
  comment out the swap file #/var/swap none swap sw
  
  http://blog.qartis.com/lazy_hardened_void_linux_raspberry_pi/
  https://medium.com/swlh/make-your-raspberry-pi-file-system-read-only-raspbian-buster-c558694de79
  https://github.com/MichaIng/DietPi/issues/2127
  
  
  Notes on Read only with Andrew:
  - went into /etc/fstab and changed the booting instruction from rw -> ro (booting instructions for subsequent boots)
  - We sorta got lucky that everything can start in ro
  - mount -v -o ro,remount / AND mount -v -o rw,remount / (to edit things)
  - Set the boot partician to ro 
  - One challenge was anything that is open in rw mode will prvent this mount command from working 
  - Important to go rw in both / and /boot file systems when making changes
  
  Notes 10/3/22:
  - mount -v -o rw,remount /
  - mount -v -o ro,remount /
  - Moved Images to home directory 
  - Andrew suggests creating a symbolic link 
  
  Notes 1/12/23:
  - ln -s /tmp /var/tmp to create a symbolic link, had to delet /var/tmp before

  Notes 1/13/23:
  - Don't forget system d custom.service and all the other services that I created thttpd, autossh.service
  - Used python to control the GPIO 17 and add it to the welcome script

  Notes 2/7/23:
  - Goal here is to configure https
  - https://domains.google.com/registrar/davidgarges.com/dns?_ga=2.125606090.1174662203.1675820831-259342301.1675820831
  - davidgarges.com A TTL 1 hour Data 34.127.85.102
  - /etc/apache2....000-defualt.conf file /var/www/html/Personal_Portfolio_Website (this changes default index)
  - Using certbot debian 10 running apache 
  https://certbot.eff.org/instructions?ws=apache&os=debianbuster
  - Crontab -e "0  0  *  *  6 certbot renew --post-hook "systemctl restart apache2" to make sure the certificate is automatically renewed
  
 - Assembled my updated version of sign using GPIO 17 to control with 3.3V. Relay upstream from the sign. Seems to work pretty well. 
