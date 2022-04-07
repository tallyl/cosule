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

echo "Installing dependencies..."
apt-get -qq update &>/dev/null

echo "Fetching Consul..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
echo "Installing Consul..."
sudo apt-get update && sudo apt-get install consul


# Setup Consul
mkdir -p /opt/consul
mkdir -p /etc/consul.d
mkdir -p /run/consul


# Move the properties file injected by cloud-init to the config folder
#mv /cloud-init/server_config.json /etc/consul.d/config.json

#mv /cloud-init/resolve.conf /etc/systemd/resolved.conf.d/consul.conf
echo " creating resolve.conf - consul.conf"
 sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo cat << EOF >  /etc/systemd/resolved.conf.d/consul.conf
[Resolve]
DNS=127.0.0.1:8600
DNSSEC=false
Domains=~consul
EOF

# Create user & grant ownership of folders
echo " createing resolved.conf"
sudo cat << EOF > /etc/systemd/resolved.conf
DNSStubListener=false
EOF

sudo systemctl restart systemd-resolved

useradd consul
chown -R consul:consul /opt/consul /etc/consul.d /run/consul

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
ExecStart=/usr/bin/consul agent -pid-file=/run/consul/consul.pid -config-dir=/etc/consul.d
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF

#sudo mv /cloud-init/consul.service /etc/systemd/system/consul.service

sudo systemctl daemon-reload
sudo systemctl enable consul.service
sudo systemctl start consul.service

sudo cat << EOF > /etc/consul.d/config.json
${config}
EOF

if [ ${agent} == 1 ]
then
  sudo apt-get install -y nginx
  sudo apt-get install -y awscli
  echo "<h1>Welcome to Grandpa's Whiskey-$HOSTNAME</h1>" | sudo tee /var/www/html/index.html
  sudo systemctl start nginx
  sudo systemctl enable nginx

 sudo cat /etc/consul.d/web.json > /dev/null <<EOF
{
  "service": {
    "name": "webserver",
    "tags": [
      "webserver"
    ],
    "port": 80,
    "check": {
      "args": [
        "curl",
        "localhost"
      ],
      "interval": "10s"
    }
  }
}
EOF
fi

exit 0

