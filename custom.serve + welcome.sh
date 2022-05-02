root@DietPi:/etc/systemd/system# cat custom.service 
[Unit]
Description=example systemd custom service unit file
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /usr/sbin/welcome.sh

[Install]
WantedBy=multi-user.target

root@DietPi:/usr/sbin# cat welcome.sh 
#!/bin/bash
#sudo thttpd -C /etc/thttpd.conf
#ssh -N -R 0.0.0.0:6001:localhost:22 -R 0.0.0.0:6082:localhost:80 -i ~/.ssh/cloud_vm garges@34.127.85.102 -o ExitOnForwardFailure=yes
#ssh -N -R 0.0.0.0:6001:localhost:22 -R 0.0.0.0:6082:localhost:80 -i ~/.ssh/cloud_vm garges@34.127.85.102
echo "Welcome.sh script was run at $(date)" >> /tmp/welcome.txt
sudo /root/write2sign.sh .
