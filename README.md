

(2) Setting up Raspberry Pi for SSH
-Setting up automatic wifi by editting the config file https://dietpi.com/phpbb/viewtopic.php?p=9#p9
  -> Open dietpi-wifi.txt and open it with wordpad
  -> Change aWIFI_SSID[0]='MySSID' and aWIFI_KEY[0]='MyWifiKey'
  -> Don't forget to also activate automatic wifi
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

(3) Setting up how to talk to the sign 

(4) Setting up the twilio 
-Getting a phone number registered (its free between mine and the registered phone number) 12488461690


(5) Setting up Web server with cgi-bin 
-wget https://acme.com/software/thttpd/thttpd-2.29.tar.gz
tar xvf ./thttpd-2.29.tar.gz 
cd into the directory
./configure (we talked abour prefix)
make
make install (gives an error with group www - doesn't seem to be significant) 
sudo apt install nvi

mkdir www/index.html 

thttpd -C /etc/thttpd.conf
-D to run it in the background

Andrew suggests translating port 80 to port 80 like we did with owncloud
mkdir www/cgi-bin with file gpio
on private network: http://Rasppi/cgi-bin/gpio will run the script like he said
don't forget about permissions to run the files 













https://forums.raspberrypi.com/viewtopic.php?t=133517
https://www.reddit.com/r/raspberry_pi/comments/2anyjr/what_is_the_easiest_way_to_sendreceive_sms_with/

Andrew's Resources:
https://github.com/qartis/misc/blob/master/pl-m2014r-serial.c

it basically just outputs a header and then writes whatever text you give it as a command line argument out to the sign
here's an example of the protocol, that explains how to write messages in different colors, etc
http://wearcam.org/ece385/prolite_documentation/ProliteProtocol.html

Pro-Lite PL-M2014R



Email Options:
-Fetchmail 

Twilio Tutorial:
https://classes.engineering.wustl.edu/ese205/core/index.php?title=Text_messaging_(Twilio_API)_%2B_Raspberry_Pi





1) Gathering Hardware:
-Raspberry Pi XXXXX
-DietPi Image https://dietpi.com/docs/install/

Twilio Recieve Example: 
https://stackoverflow.com/questions/25608443/how-to-receive-twilio-sms-to-command-raspberry-pi






-Downloading the owncloud software with command dietpi-config
-Logging in on local network 10.0.0.197/owncloud admin dietpi
  -> The sample data is located in /mnt/dietpi_userdata/owncloud_data/admin/files

-Mounting the external drive with correct ownership: sudo mount -o umask=0,uid=111,gid=33 /dev/sdc1 /media/usb
  -> lsblk to see where the drive is
  -> cat /etc/group to see: redis:x:111:www-data
  -> cat /etc/passwd to see: www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin 
  -> ls -l to compare permissions 
  -> Will have to remount if disconnected and if restarted
  -> I have confirmed that I can remove the drive and see the files on it and then get it back there 
-Creating path in the owncloud web GUI: admin > storage (in admin section) > External Storage:local > configuration:/media/usb/

scp -i ~/.ssh/cloud_vm ~/Downloads/thttpd-2.29.tar.gz garges@34.127.85.102:~/thttpd-2.29.tar.gz (logged into macbook)
https://www.techrepublic.com/article/use-thttpd-as-your-web-server-when-apache-is-overkill/
scp -i ~/.ssh/cloud_vm garges@34.127.85.102:~/thttpd-2.29.tar.gz (logged into raspberry pi)

sudo apt-get install file
tar xvf ./thttpd-2.29.tar.gz 


wget https://acme.com/software/thttpd/thttpd-2.29.tar.gz
tar xvf ./thttpd-2.29.tar.gz 
cd into the directory
./configure (we talked abour prefix)
make
make install (gives an error with group www - doesn't seem to be significant) 
sudo apt install nvi

mkdir www/index.html 

thttpd -C /etc/thttpd.conf
-D to run it in the background

Andrew suggests translating port 80 to port 80 like we did with owncloud
mkdir www/cgi-bin with file gpio
on private network: http://Rasppi/cgi-bin/gpio will run the script like he said
don't forget about permissions to run the files 

