#!/bin/bash
ip=$1
declare -i hostexist=$(/usr/bin/onehost list | grep "$ip" | /usr/bin/wc -l )
HID=$(/usr/bin/onehost list | grep "$ip" | awk 'NR==1 {print $1}')
if [ "$hostexist" != "0" ]; then
    /usr/bin/onehost delete $HID
fi
/usr/bin/onehost create ${ip} im_kvm vmm_kvm tm_nfs
#/usr/bin/onehost create ${ip} im_kvm vmm_kvm tm_shared dummy
