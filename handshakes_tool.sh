#!/bin/bash
#
#********************************************************************
#Author:                QianSong
#QQ:                    xxxxxxxx
#Date:                  2022-10-03
#FileName：             handshakes_tool.sh
#URL:                   https://github.com
#Description：          The handshakes tools select script
#Copyright (C):         QianSong 2022 All rights reserved
#********************************************************************

#ding yi source dir var
source_dir=$(dirname $(realpath $0))/handshakes-tool-scripts

#pan duan shi fou root yon hu yun xing
if [ "${UID}" != "0" ]; then
	echo -e "\033[31mBerechtigung verweigert, bitte führen Sie dieses Skript als root aus.\033[0m"
	exit 1
fi

#===========================================================================================================================================
#=====================                                            print app info                                 ===========================
#===========================================================================================================================================
clear
echo -e "\033[35mWMWMWMWMWMWMWMWMWMWMWMWMWMWMWWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM\033[0m"
sleep 0.1
echo -e "\033[31m                 *\033[0m"
sleep 0.1
echo -e "\033[31m              *      *\033[0m"
sleep 0.1
echo -e "\033[31m                 *\033[0m"
sleep 0.1
echo -e "\033[31m                    **********************************************\033[0m"
sleep 0.1
echo -e "\033[31m                 *                                                *\033[0m"
sleep 0.1
echo -e "\033[32m< JJ 18 CM >\033[0m     \033[31m*                                           *******\033[0m"
sleep 0.1
echo -e "\033[31m                 *                                                *\033[0m"
sleep 0.1
echo -e "\033[31m                    **********************************************\033[0m"
sleep 0.1
echo -e "\033[31m                 *\033[0m"
sleep 0.1
echo -e "\033[31m              *      *\033[0m"
sleep 0.1
echo -e "\033[31m                 *\033[0m"
sleep 0.1
echo -e "\033[35mWMWMWMWMWMWMWMWMWMWMWMWMWMWMWWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM\033[0m"
sleep 0.1

#print process info
i=1
while [ ${i} -lt 5 ]; do
	for char in '/' '.' '\'
	do
		echo -n "                                  [${char}]                                    "
		echo -ne "\r\r"
		sleep 0.2
	done
	let i++
done
echo -e "\n"
sleep 0.3

#===========================================================================================================================================
#==================                                 an zhuang yi lai ruan jian function                          ===========================
#===========================================================================================================================================
install_dependent_software() {
apt update
if [ $? -ne 0 ]; then
	echo -e "\033[31mNetzwerkfehler\033[0m"
	exit 2
fi
apt install $1 -y
if [ $? -ne 0 ]; then
	echo -e "\033[31mNetzwerkfehler\033[0m"
	exit 3
fi
}

#pan  duan  shi  fou  an zhuang  le  yi  lai  ruan  jian
for i in mdk3 mdk4 airmon-ng airodump-ng xterm dos2unix cowpatty aireplay-ng macchanger
do
	type ${i} >/dev/null 2>&1
	exit_code=$?
	if [ ${exit_code} -eq 0 ]; then
		echo -e "${i}.....................\033[32mOK\033[0m"
	else
		echo -e "${i}.....................\033[33mInstalliere\033[0m"
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
			aireplay-ng)
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
			macchanger)
				install_dependent_software macchanger
				;;
			*)
				echo -e "\033[31mUknown error..\033[0m"
				exit 4
				;;
		esac
	fi
	sleep 0.1
done

#===========================================================================================================================================
#=====================                               check and kill wlan card busy pid                           ===========================
#===========================================================================================================================================
airmon-ng check kill >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo -e "\033[31mFehler beim Prüfen des gestörten Prozesses, Beenden!!\033[0m"
	exit 1
fi

#===========================================================================================================================================
#=====================                                        print notice info                                  ===========================
#===========================================================================================================================================
echo -e "\n"
echo -e "\033[33mDas Laden ist abgeschlossen! Es startet für Sie, bitte warten Sie ein paar Sekunden für das Huhn .......\033[0m"
sleep 5
clear

#===========================================================================================================================================
#====================                                      xuan zhe gon ji tool function                             =======================
#===========================================================================================================================================
handshake_tool_menu() {
echo -e "\033[33mWählen Sie ein Werkzeug aus, das Sie verwenden möchten\033[0m"
echo -e "\033[36m************************************\033[0m"
echo -e "\033[32m1.        mdk-tool(empfohlen)\033[0m           \033[36m*\033[0m"
echo -e "\033[32m2.        aireplay-tool(Alternative)\033[0m      \033[36m*\033[0m"
echo -e "\033[36m************************************\033[0m"
read -p "Please select: " handshake_tool
case ${handshake_tool} in
	1)
		clear
		source ${source_dir}/handshakes_by_mdk.sh
		;;
	2)
		clear
		source ${source_dir}/handshakes_by_aireplay.sh
		;;
	*)
		clear
		handshake_tool_menu
		;;
esac
}

#yun  xing  function ru  kou
handshake_tool_menu
