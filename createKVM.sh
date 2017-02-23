#!/bin/bash

kvm_config_dir="/etc/libvirt/qemu/"
kvm_conig_tmp="./tmp/tmp.xml"
image_dir="/dev/vm-guest/"
centos_image="zw001"
ubuntu_image="zw002"
MACADDR=""

function createLV() {
   lv_lable=$1
   #echo $lv_lable
   echo "[+]:creating logical volume......"
   if [ -b ${image_dir}${lv_lable} ];then
       echo "[*]:ERROR: logical volume \"$lv_lable\" is exist,please to confirm it what run lvdisplay or lvs command."
       exit 1
   fi
   echo "[+]:beigging create logical volume......"
   lvcreate  -n $lv_lable  -L 10G  vm-guest && lvcreate  -n ${lv_lable}-data  -L 20G  vm-guest
   if [ $? -eq 0 ];then
       echo "[-]:INFO: logical volume \"$lv_lable\" is created,please to confirm it what run lvdisplay or lvs command."
       return 0   
   else
       echo "[*]:ERROR: to create logical volume has occurred!"
       exit 1
   fi
}

function createImage(){
   image=$1
   platform=$2
   echo "[+]:create image of $image,please wait a few minutes......"
   if [ "$platform" == "centos" ];then
       echo "[+]:dd if=${image_dir}zw001  of=${image_dir}${image}  bs=4M"
       dd if=${image_dir}zw001  of=${image_dir}${image}  bs=4M 
   elif [ "$platform" == "ubuntu" ];then
       echo "dd if=${image_dir}zw002  of=${image_dir}${image}  bs=4M"
       dd if=${image_dir}zw002  of=${image_dir}${image}  bs=4M
   else
       echo "[*]:platform not found."
       exit 1
   fi   
}

function gen_mac_address {
    echo "[+]:generating MAC address......"
    MACADDR="52:54:$(dd if=/dev/urandom count=1 2>/dev/null | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\).*$/\1:\2:\3:\4/')"
    echo "[-]:MAC ADDRESS : $MACADDR"
}

function createXML(){
    # $1 platform: centos ubuntu .....
    # $2 xml file name
    # $3 mac address
    echo "[+]:generating kvm config......"
    xml_name="${kvm_config_dir}${2}.xml"
    echo $xml_name
    cp $kvm_conig_tmp $xml_name
    sed -i "s/centos-clone01/$1-$2/g" $xml_name
    sed -i "s/zw002/$2/g" $xml_name
    sed -i "s/52:54:00:15:fc:79/$3/g" $xml_name
    return 0 
}

function createKVM(){
    # $1 xml file name
    # $2 platform
    echo "[+]creating kvm......"
    xml_name="${kvm_config_dir}${1}.xml"
    echo "[+]:creating kvm of $2-$1......"   
    virsh  create $xml_name  2>/dev/null 1>/dev/null
    if [ $? -eq 0 ];then
        echo "[-]:create kvm $2-$1 is finished." 
    else
        echo "[*]:ERROR: to create kvm has occurred!"
        exit 1
    fi
}

function Usage {
    echo "Usage:"
    echo "	createKVM.sh platform virtual-serve-rname"
    echo "	- platform: [centos|ubuntu]"
    echo "	- virtual-serve-rname: User-Defined"
}

function main() {
   if [ $# -lt 2 ];then
       Usage
       exit 1
   fi
   #echo "$@"
   platform=$1
   vserver_name=$2   
   createLV  $vserver_name
   createImage $vserver_name $platform
   gen_mac_address
   createXML $platform $vserver_name $MACADDR
   createKVM  $vserver_name $platform 
   echo "[+]:finish"
}

main "$@"
