#!/bin/bash -x
sleep 60
sudo apt-get update
sudo apt-get install liblzma-dev -y
sudo apt install build-essential zlib1g-dev libncurses5-dev \
libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev \
libreadline-dev libffi-dev curl libbz2-dev curl -y

#install python3.10.6
curl -O https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tar.xz

tar -xf Python-3.10.6.tar.xz
cd Python-3.10.6/ &&
./configure --enable-optimizations

nproc=$(nproc)
make -j "$nproc"
sudo make altinstall
python3.10 --version

sudo update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.10 1

echo "CDN=100.125.1.250" >>/etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved.service
sudo mv /etc/resolv.conf /etc/resolv.conf.bak
sudo ln -s /run/systemd/resolve/resolv.conf /etc/

yes y | head -1 | apt install expect
/usr/bin/expect <<EOF
spawn adduser aigc
expect "New password:"
send "aigc@123\r"
expect "Retype new password:"
send "aigc@123\r"
expect "Full Name"
send "\r"
expect "Room Number"
send "\r"
expect "Work Phone"
send "\r"
expect "Home Phone"
send "\r"
expect "Other"
send "\r"
expect "Y/n"
send "Y\r"
expect eof
exit
EOF

sudo apt -y install git python3.10-venv
sudo usermod -aG sudo aigc

#install stable-diffusion-webui
wget -P /home/aigc/ https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh
cd /home/aigc &&
sudo chmod +777 /home/aigc/webui.sh
nohup sudo -u aigc bash -c "source /home/aigc/webui.sh --listen --port 7860 --api --enable-insecure-extension-access &" >> /home/aigc/aigc-applications.log

#install obsutil
wget -O /home/aigc/obsutil.tar.gz https://obs-community.obs.cn-north-1.myhuaweicloud.com/obsutil/current/obsutil_linux_amd64.tar.gz
mkdir -p /home/aigc/obsutil
tar xf /home/aigc/obsutil.tar.gz --strip-components 1 -C /home/aigc/obsutil
chmod 755 /home/aigc/obsutil
/home/aigc/obsutil/obsutil config -i=$1 -k=$2 -e=obs.ap-southeast-3.myhuaweicloud.com
sudo apt-get -y install inotify-tools
sleep 30
mkdir -p /home/aigc/stable-diffusion-webui/log/images/
sudo chmod -R +777 /home/aigc/stable-diffusion-webui/log

sudo cp /lib/systemd/system/rc-local.service /etc/systemd/system
echo "[Install]" >> /etc/systemd/system/rc-local.service
echo "WantedBy=multi-user.target"  >> /etc/systemd/system/rc-local.service
echo "Alias=rc-local.service" >> /etc/systemd/system/rc-local.service
touch /home/aigc/stable-diffusion-webui/log/update_obs.log
chmod +777 /home/aigc/stable-diffusion-webui/log/update_obs.log
cat>/home/aigc/upload_files.sh<<EOF
#!/usr/bin/env bash
inotifywait -m -e moved_to --format '%w%f' /home/aigc/stable-diffusion-webui/log/images/ | while read file
do
    echo "start update..." >> /home/aigc/stable-diffusion-webui/log/update_obs.log
    /home/aigc/obsutil/obsutil cp \$file obs://$3/ >> /home/aigc/stable-diffusion-webui/log/update_obs.log
    echo "update end" >> /home/aigc/stable-diffusion-webui/log/update_obs.log
done
EOF

cat>/home/aigc/auto_aigc.sh<<EOF
#!/usr/bin/env bash
cd /home/aigc && sudo -u aigc bash -c "source /home/aigc/webui.sh --listen --port 7860 --api --enable-insecure-extension-access &" >> /home/aigc/aigc-applications.log
EOF

sudo chmod +x /home/aigc/upload_files.sh /home/aigc/auto_aigc.sh

cat>>/etc/rc.local<<EOF
#!/usr/bin/env bash
sh /home/aigc/auto_aigc.sh &
sh /home/aigc/upload_files.sh &
EOF
sudo chmod +x /etc/rc.local
sh /home/aigc/upload_files.sh &