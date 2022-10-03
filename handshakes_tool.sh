#!/bin/bash
#
#********************************************************************
#Author:                QianSong
#QQ:                    1725099638
#Date:                  2022-10-03
#FileName：             handshakes_tool.sh
#URL:                   https://github.com/QianSong1
#Description：          The handshakes tools select script
#Copyright (C):         QianSong 2022 All rights reserved
#********************************************************************

#ding yi source dir var
source_dir=$(dirname $(realpath $0))/handshakes-tool-scripts

#xuan zhe gon ji tool
handshake_tool_menu() {
cat <<EOF
Select one tool what you want to use
************************************
1.        mdk-tool(推荐)           *
2.        aireplay-tool(备选)      *
************************************
EOF
}

#yun  xing  function ru  kou
while true
do
	handshake_tool_menu
	read -p "Please select: " handshake_tool
	case ${handshake_tool} in
		1)
			source ${source_dir}/handshakes_by_mdk.sh
			;;
		2)
			source ${source_dir}/handshakes_by_aireplay.sh
			;;
		*)
			clear
			;;
	esac
done
