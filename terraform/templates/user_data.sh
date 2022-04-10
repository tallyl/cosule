#!/usr/bin/env bash

# Set logging
#export LOGFILE=/tmp/server_user_data.log
exec > /tmp/server_user_data.log
exec 2>&1

echo "Started user data script at $(date)"

# Metadata
export AWS_AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
#export AWS_REGION=$$(echo $${AWS_AZ} | sed 's/[a-z]$//')
#export INSTANCE_ID=$$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
#export INSTANCE_TYPE=$$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document/ | grep instanceType | cut -d":" -f2 | tr -d "\", ")
#export ACCOUNT_ID=$$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -oP '(?<="accountId" : ")[^"]*(?=")')

sudo apt-get install -y awscli

# Set region for CLI
mkdir -p ~/.aws
cat > ~/.aws/config << EOF
[default]
region = $${AWS_REGION}
EOF

# Set region for awslogs
cat << EOF > /etc/awslogs/awscli.conf
[plugins]
cwlogs = cwlogs
[default]
region = $${AWS_REGION}
EOF


### set consul version
CONSUL_VERSION="1.8.5"

echo "Grabbing IPs..."
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)


# Setup Consul
echo " Creating directories"
sudo mkdir -p /opt/consul
sudo mkdir -p /etc/consul.d
sudo mkdir -p /run/consul


echo " Download and install consul software"
echo "Fetching Consul..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"


echo "Installing Consul..."
sudo apt-get update && sudo apt-get install consul

echo " downloading DNSMASQ"
sudo apt-get -qq update &>/dev/null
sudo apt-get -yqq install unzip dnsmasq &>/dev/null

sudo echo "server=10.0.0.2" >> /etc/dnsmasq.conf

echo "Configuring dnsmasq..."
cat << EODMCF > /etc/dnsmasq.d/10-consul
# Enable forward lookup of the 'consul' domain:
server=/consul./127.0.0.1#8600
EODMCF


echo " setting resolv.conf"
sudo cat << EOF > /etc/resolv.conf
nameserver 127.0.0.1
EOF

# Stop & disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

sudo systemctl restart dnsmasq


#sudo sed -i "s/#Domains=/Domains=~service.consul./g" /etc/systemd/resolved.conf


echo " Adding user consul"
useradd consul
sudo chown -R consul:consul /opt/consul /etc/consul.d /run/consul


#echo " creating resolve.conf - consul.conf"
#sudo cat << EOF >  /etc/systemd/resolved.conf
#[Resolve]
#DNS=127.0.0.1
#Domains=~consul.
#EOF





#sudo systemctl restart systemd-resolved



#sudo systemctl stop systemd-resolved
#sudo systemctl disable systemd-resolved
#sudo systemctl mask systemd-resolved


#echo "Installing dependencies..."
#apt-get -qq update &>/dev/null
#wget https://releases.hashicorp.com/consul/1.8.5/consul_1.8.5_linux_amd64.zip


# Configure consul service
sudo cat << EOF > /etc/systemd/system/consul.service
[Unit]
Description=Consul service discovery agent
Requires=network-online.target
After=network.target

[Service]
User=consul
Group=consul
PIDFile=/run/consul/consul.pid
Restart=on-failure
Environment=GOMAXPROCS=2
ExecStartPre=+/bin/mkdir -p /run/consul
ExecStartPre=+/bin/chown consul:consul /run/consul
ExecStart=/usr/bin/consul agent -pid-file=/run/consul/consul.pid -config-dir=/etc/consul.d
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF

#sudo mv /cloud-init/consul.service /etc/systemd/system/consul.service

sudo cat << EOF > /etc/consul.d/config.json
${config}
EOF

sudo systemctl daemon-reload
sudo systemctl enable consul.service
sudo systemctl start consul.service


if [ ${agent} == 1 ]
then
  sudo apt-get install -y nginx
  echo "<h1>Welcome to Grandpa's Whiskey-$HOSTNAME</h1>" | sudo tee /var/www/html/index.html
  sudo systemctl start nginx
  sudo systemctl enable nginx

 sudo cat << EOF > /etc/consul.d/web.json
{
      "service": {
        "name": "webserver",
        "tags": [
          "webserver"
        ],
        "port": 80,
        "check": {
          "id": "web",
          "name": "NGINX responds at port 80",
          "http": "http://localhost",
          "interval": "10s"
        }
     }
}
EOF


fi

sudo systemctl restart consul.service

exit 0

