#!/bin/bash
# Author: Chang-Hsing Wu <hsing _at_ nchc narl org tw>
#         Serena Yi-Lun Pan <serenapan _at_ nchc narl org tw>
# License: GPL
# Program:
#  This Ezilla project disk version install 
# History:
# 2012/01/X
# Owner : NCHC Percomp Lab

: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_HELP=2}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ITEM_HELP=4}
: ${DIALOG_ESC=255}



Dialog=/usr/bin/dialog
#Dialog=/usr/bin/whiptail
#check_exit 
function createKSFile(){
        cp ks-cli-example.cfg ks-cli.cfg
	cat /etc/exports | grep "###Export CDROM" >> /dev/null
	if [ $? != 0 ]; then
		echo "###Export CDROM" >> /etc/exports
		echo "/media/cdrom 192.168.100.0/24(rw,no_root_squash)" >> /etc/exports
		echo "###Export /var/lib/one" >> /etc/exports
	fi
	if [ $1 == "MooseFS" ];then

		if [ $2 == "2" ];then
		declare -i modify_line=$(cat -n ks-cli.cfg | grep '###Partition Disk' | awk 'NR==1 {print $1}')
                start_line=`expr ${modify_line} + 1`
                sed -i "${start_line}i \  clearpart --all --initlabel --drives=$partition \npart /boot --fstype=ext4 --size=500 --ondisk=$part_A \npart / --fstype=ext4 --grow --size=1 --ondisk=$part_A \npart swap --recommended \npart /moosefs --fstype=ext4 --grow --size=1 --ondisk=$part_B" ks-cli.cfg
		else
		declare -i modify_line=$(cat -n ks-cli.cfg | grep '###Partition Disk' | awk 'NR==1 {print $1}')		
		start_line=`expr ${modify_line} + 1`
		sed -i "${start_line}i \ clearpart --all --initlabel --drives=$partition \npart /boot --fstype=ext4 --size=500 --ondisk=$part_A \npart / --fstype=ext4 --grow --size=1 --ondisk=$part_A \npart swap --recommended" ks-cli.cfg
		fi
	elif [ $1 == "NFS" ]; then
                declare -i modify_line=$(cat -n ks-cli.cfg | grep '###Partition Disk' | awk 'NR==1 {print $1}')
                start_line=`expr ${modify_line} + 1`
		sed -i "${start_line}i \  clearpart --all --initlabel --drives=$partition \npart /boot --fstype=ext4 --size=500 --ondisk=$part_A \npart / --fstype=ext4 --grow --size=1 --ondisk=$part_A \npart swap --recommended"  ks-cli.cfg
		declare -i modify_line=$(cat -n /etc/exports | grep '###Export /var/lib/one' | awk 'NR==1 {print $1}')
		start_line=`expr ${modify_line} + 1`
	        sed -i "${start_line}c \/var/lib/one    192.168.100.0/24(rw,no_root_squash)" /etc/exports
                declare -i modify_line=$(cat -n ks-cli.cfg | grep '###Script' | awk 'NR==1 {print $1}')
		start_line=`expr ${modify_line} + 2`
		sed -i "${start_line}i \echo \'192.168.100.254:/var/lib/one	/var/lib/one	nfs defaults 0 0 >> /etc/fstab\' " ks-cli.cfg		
	else
                declare -i modify_line=$(cat -n ks-cli.cfg | grep '###Partition Disk' | awk 'NR==1 {print $1}')
                start_line=`expr ${modify_line} + 1`
		sed -i "${start_line}i \clearpart --all --initlabel --drives=$partition \npart /boot --fstype=ext4 --size=500 --ondisk=$part_A \npart / --fstype=ext4 --grow --size=1 --ondisk=$part_A \npart swap --recommended \n" ks-cli.cfg
	fi
}
function check_partition(){

str_length=`expr length "$partition"`
	
		if [ $str_length == "11" ]; then
			part_A=`expr substr "$partition" 2 3`
			part_B=`expr substr "$partition" 8 3`
			partition=$part_A,$part_B
			disks_num=2
		elif [ $str_length == "9" ]; then
			part_A=`expr substr "$partition" 2 3`
			part_B=`expr substr "$partition" 6 3`
			partition=$part_A,$part_B
			disks_num=2
		elif [ $str_length == "5" ]; then
			part_A=`expr substr "$partition" 2 3`
			partition=$part_A
			disks_num=1
		else
			temp=`expr length "$partition"`
			partition_error=1
		fi

}
function check_exit(){
	$Dialog --clear \
		--backtitle $projectName \
		--yesno  "Really Quit ?" 10 30 
		case $? in
		$DIALOG_OK)
			exit
			;;
		$DIALOG_CANCEL)
			returncode=99
			continue
			;;
		esac
}
#The node_num function : collect node 
function node_num(){

while test $returncode != "$DIALOG_CANCEL" && test $returncode != "$DIALOG_ESC"
do

	$Dialog --backtitle $projectName  \
		--inputbox "How many client node in your environments?(1-220)" 10 75 \
		"$errMsg" 2>$INPUT
	returncode=$?
	clientNum=`cat $INPUT`
	errMsg=''		
	case $returncode in 
	$DIALOG_OK) 
		clientNum=`echo $clientNum | grep [[:digit:]]`
		if [ "$clientNum" == "" ]; then
			errMsg='typing format error (e)'
			continue
		
		elif [ "$clientNum" -ge 1 ] && [ "$clientNum" -le 220 ]; then
			return
		else
			errMsg='typing error'
			continue
		fi
		;;
	$DIALOG_CANCEL)
		check_exit
		;;	
	esac
done
}

#The disk_partition function : collect user environment to install ezilla 
function disk_partition(){
FS='File System'
SCP='The OS_Image transport by scp proctol'
NFS='The OS_Image put on Network File System'
MooseFS='The OS Image put on moose file system'
disk_partition_title='What kind of the disk is used to install ezilla project on your server?'
disk_partition_title_adv='Entering your disk partition for installing  Ezilla Projet(Exmaple sda,sdb)'
test2=''

while test $returncode != "$DIALOG_CANCEL" && test $returncode != "$DIALOG_ESC"
do
$Dialog --extra-button --extra-label "advanced-mode" \
	--backtitle $projectName \
	--checklist "$disk_partition_title\n
	$partitionErrMsg" 15 70 40 \
	'sda' sda off \
	'sdb' sdb off \
	'hda' hda off \
	'hdb' hdb off \
	2>$INPUT
	returncode=$?
	partition=`cat $INPUT`
	
	case $returncode in 
	$DIALOG_OK)
		if [ "$partition" == "" ]; then
			partitionErrMsg="Don't choose any options"
			continue;
		fi
		check_partition
		return 
		;;	
	$DIALOG_EXTRA)
		while test $returncode != "$DIALOG_CANCEL" && test $returncode != "$DIALOG_ESC"
		do
			$Dialog	--backtitle $projectName \
				--inputbox "$disk_partition_title_adv \n 
				$partitionErrMsg" 10 75  \
				"" 2>$INPUT
			returncode=$?
			partition=`cat $INPUT |grep [[:lower:]]`
			case $returncode in 
			$DIALOG_OK)
				if [ "$partition" == "" ]; then
					partitionErrMsg='typing error'
					continue
				fi
					partition=\"$partition\"
					check_partition					
				
				if [ "$partition_error"	== "1" ] ; then
					partitionErrMsg='typing error'
					continue
				fi
					return
			;;	
			$DIALOG_CANCEL)
				check_exit
			;;
			esac
		done
		;;
	$DIALOG_CANCEL)
		check_exit
		;;
	esac
done
}

function choose_FileSys(){
while test $returncode != "$DIALOG_CANCEL" && test $returncode != "$DIALOG_ESC"
do
        $Dialog --backtitle $projectName \
                --title "$FS"   \
                --menu "$menuData" 15 70 40 \
                'SCP' "$SCP" \
                'NFS' "$NFS" \
                'MooseFS' "$MooseFS" \
                2>"${INPUT}"
        returncode=$?
	fileSystem=`cat $INPUT`
	
        case $returncode in
        $DIALOG_OK)
                echo `cat $INPUT`
			return
        ;;
        $DIALOG_CANCEL)
                check_exit
        ;;
        esac
done


}
function network_setup(){
$Dialog --backtitle $projectName --title "network" --form "setup" 15 50 0 \
	"Device:"	1 1 "$Device"	1 10 10 0 \
	"IP:"
}
function setup_over(){
endMessage='Installation has been completed , please  booting the clinet node for next step'
	$Dialog --aspect 10 \
		--backtitle $projectName --title "Install over" \
		--msgbox "$endMessage"	0 0
#	exit
}
function display_var(){
echo "clientNum"+$clientNum > var
echo "partition"+$partition >> var
echo "fileSystem"+$fileSystem >> var
	$Dialog --aspect 10 \
		--backtitle $projectName \
		--title "environmental setup variable" \
		--msgbox "clientNum=$clientNum\n
			partition=$partition\n
			fileSystem=$fileSystem" 0 0
}

#main function
TEXTDOMAIN=ezilla_install
TEXTDOMAINDIR=/home/jonathan/working_ezilla/locale
export TEXTDOMAIN TEXTDOMAINDIR
INPUT=/tmp/tmp_ezilla_install
projectName=`gettext "Ezilla"`
titleData=`gettext "[MAIN_MENU]"`
menuData=`gettext 'You Can use the UP/Down arrow keys, 
the first letter of the choice as a hot key,
or the number keys 1-9 to choose an option.
Choose the TASK'`
select1_detail=`gettext 'Ezilla Project Client Installation'`
select2_detail=`gettext 'Ezilla Project Uninstall'`
select3_detail=`gettext 'Exit Installation'`
#echo $menuData
#echo $select1_detail
#echo $select2_detail
#echo $select3_detail
ans=''
returncode=99
## Main menu
        
while test $returncode != "$DIALOG_CANCEL" && test $returncode != "$DIALOG_ESC"
do
	$Dialog --backtitle $projectName \
                --title $titleData --menu "$menuData" 15 50 10 \
                Client-Install "$select1_detail" \
                Uninstall "$select2_detail" \
                Exit "$select3_detail" \
                2>"${INPUT}"
		returncode=$?
		ans=`cat $INPUT`
#		echo $returncode
		case $returncode in
			"$DIALOG_OK")
			case $ans in
				"Client-Install")
				menuData_CI='U can select Install mode on this section'
				titleData_Install="Client-Install"
				select1_default_detail='Default Install'
				select2_custom_detail='Custom Installl'
		while test $returncode != 1 && test $returncode != 250
		do	
				$Dialog --clear --backtitle $projectName \
					--title $titleData_Install \
					--menu "$menuData_CI" 15 50 10 \
					Default "$select1_default_detail" \
					Custom "$select2_custom_detail" \
					2>"${INPUT}"
					ans2=`cat $INPUT`
				returncode=$?
	
				case $returncode in 
					"$DIALOG_OK")
					case $ans2 in
						"Default")
                        	        		node_num
#							createKSFile 
							setup_over
							display_var
							exit
						;;
		       	                        "Custom")
							node_num
        	        		                disk_partition
							choose_FileSys
							createKSFile $fileSystem $disks_num
							setup_over
							display_var
							expr length '$partition'
							echo $str_length
							echo $disks_num
							echo $partition_error
							echo $temp
							exit
						;;
						*)
							check_exit
						;;
						esac
					;;
					"$DIALOG_CANCEL")
						check_exit	
					;;
		
				esac
		done
				;; #Client-Install is over
				"Uninstall")
				echo uninstall
				check_exit
				;; # Uninstall is over
	                       	"Exit") 
				echo "Good Bye!!"
	                        check_exit
				;; # Exit is over
				#default
				*)
				$Dialog --clear --backtitle $projecName \
	                        --title "Error Message" \
                                --msgbox "`cat $INPUT`" \
                                10 41
			esac
			;; # DIALOG_OK
			"$DIALOG_CANCEL")
				check_exit
				;;
			*)
			check_exit
			;;
		esac
	
done


