This project attempts to utilize a raspberry pi as an SMS access point (through Twilio) to control an LED matrix

(1) Gathering Hardware:
-Raspberry Pi 4 Model B
-SD Card
-Pro-Lite PL-M2014R

(2) Setting up Raspberry Pi as a Web Server for Twilio Access
-DietPi Image https://dietpi.com/docs/install/
-Setting up automatic wifi by editting the config file https://dietpi.com/phpbb/viewtopic.php?p=9#p9
  -> Open dietpi-wifi.txt and open it with wordpad
  -> Change aWIFI_SSID[0]='MySSID' and aWIFI_KEY[0]='MyWifiKey'
  -> Don't forget to also enable automatic wifi in another file
  -> Probably should put in the phone's tether wifi(s) for automatic connection
-Setting up ssh key for raspberry pi from laptop: ssh -i TextMessageSign root@10.0.0.128
  -> using the diet-config command to change ssh to OpenSSH and not Dropbear
  -> Use ssh-keygen to generate a key with custom name and adding the .pub file to ~/.ssh/authorized_keys (remember to respond "Yes")
  -> This process I used a thumb drive to transfer and mount the file (mkdir /media/usb; sudo mount -o umask=0,uid=111,gid=33 /dev/sdc1 /media/usb; lsblk)
-Setting up ssh key for cloud_vm from raspberry pi: ssh -i ~/.ssh/cloud_vm garges@34.127.85.102
  -> Use ssh-keygen on raspberry pi to generate a key with custom name and adding .pub file to ~/.ssh/authorized_keys (remember to respond "Yes")
-Setting up reverse tunnelling between cloud vm and raspberry pi
  -> Testing out the reverse tunnel ssh -N -R 0.0.0.0:6001:localhost:22 -i ~/.ssh/Cloud_vm garges@34.127.85.102 and follow with ssh -p 6001 root@localhost
  -> Using port 6001 here because there was a conflict with the reverse tunnelling known_hosts with the owncloud_pi 
  -> Creating tunnel.sh with correct permissions (chmod 777 tunnel.sh) and adding in ssh -N -R 0.0.0.0:6001:localhost:22 -i ~/.ssh/cloud_vm garges@34.127.85.102
  -> crontab -e to open the cron tab and */1 * * * * ~/tunnel.sh > tunnel.log 2>&1
-Installing Web Server with CGI-bin
  -> wget https://acme.com/software/thttpd/thttpd-2.29.tar.gz
  -> tar xvf ./thttpd-2.29.tar.gz (unzip package)
  -> cd into the directory
  -> ./configure (can add a prefix for the directories)
  -> make; make install (gives an error with group www - doesn't seem to be significant)
  -> sudo apt install nvi
  -> mkdir www/index.html (this is the static site)
  -> thttpd -C /etc/thttpd.conf (can add -D to run this in the background)


Andrew suggests translating port 80 to port 80 like we did with owncloud
mkdir www/cgi-bin with file gpio
on private network: http://Rasppi/cgi-bin/gpio will run the script like he said
don't forget about permissions to run the files 


(3) Setting up Twilio as an access point 
-Creating number - 12488461690
-Setting up and configuring webhook

(4) Getting code for the sign to work:
https://github.com/qartis/misc/blob/master/pl-m2014r-serial.c
it basically just outputs a header and then writes whatever text you give it as a command line argument out to the sign
here's an example of the protocol, that explains how to write messages in different colors, etc
http://wearcam.org/ece385/prolite_documentation/ProliteProtocol.html

