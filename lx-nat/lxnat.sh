#!/bin/bash
if [[ $(id -u) -ne 0  ]];then
        echo "Cannot access file: permission denied"
        exit 1
fi

function error(){
	echo "[ERROR]: $1"

}

function is_ipforward_configured(){
   if [[ $(cat /proc/sys/net/ipv4/ip_forward) -eq 1 ]];then
                echo "Forwarding configured succcessfully"
        else
                error "Forwarding failed"
		exit 1
   fi

}

function install_iptables(){
	is_iptables_installed="/usr/sbin/iptables"

	if [[ $is_iptables_installed != "/usr/sbin/iptables" ]];then
                echo "Updating system...";sleep 1
		apt update && apt upgrade -y
		if [[ $? -ne 0 ]];then
		    error "WAN interface has gone, please fix it inmediatly"
		    exit 1
		fi
		echo ""
                echo "Installing iptables..";sleep 1
                apt install iptables
        else
            echo "iptables is already installed"
        fi


}

function config_iptables(){
	echo "Configuring nat in iptables...";sleep 1
        iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE

}

#Variables
ipforward=$(cat /etc/sysctl.d/sysctl.conf | grep ^net.ipv4.ip_forward=1$)

if [[ -f /etc/sysctl.conf ]];then #This condition is only valid for Ubuntu
	echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/sysctl.conf
        echo "Keeping changes..";sleep 1
        sysctl -p /etc/sysctl.conf

        is_ipforward_configured

        config_iptables

elif [[ ! -f /etc/sysctl.d/sysctl.conf  ]];then

        error "sysctl.conf does not exist"
        echo "Creating file...";sleep 1
        touch /etc/sysctl.d/sysctl.conf

        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/sysctl.conf
        echo "Keeping changes..";sleep 1
        sysctl -p /etc/sysctl.d/sysctl.conf

        is_ipforward_configured

        install_iptables

        config_iptables


elif [[ -f /etc/sysctl.d/sysctl.conf  ]];then

	if [[ $ipforward == "net.ipv4.ip_forward=1" ]];then
            echo "sysctl.conf is already configured"
        else
             echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/sysctl.conf
             echo "Keeping changes..";sleep 1
             sysctl -p /etc/sysctl.d/sysctl.conf
        fi

	is_ipforward_configured

        install_iptables

	config_iptables
else
    echo "NAT is already configured"
fi
