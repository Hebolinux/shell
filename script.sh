#!/bin/bash
#
#获取用户输入的函数
get_answer(){
	unset ANSWER
	ASK_COUNT=0
	read -t 60 ANSWER
	while [ -z $ANSWER ]
	do
		$ASK_COUNT=$[ $ASK_COUNT + 1 ]
		case $ASK_COUNT in
			2)
				echo "\nWaiting for input the second time"
				;;
			3)
				echo "\nWaiting for input the last time"
				;;
			4)
				echo "\nWait for the input to time out and exit the script"
				exit
				;;
		esac
		if [ -z $LINE2 ] 
		then
			echo -e "$LINE1 \c"
		else
			echo -e "$LINE1 \c"
			echo -e "$LINE2 \c"
		fi
		read -t 60 ANSWER
	done
	unset LINE1
	unset LINE2
}
LINE1="Please enter the username to delete: \c"
get_answer
USER_ACCOUNT=$ANSWER	#将ANSWER的值给USER_ACCOUNT，这里表示获取用户输入的用户名
#
#---------------------------------------------分割符---------------------------------------------------
#
#再次确认用户操作的函数
process_answer(){
	case $ANSWER in
		Y|y|YES|yes|Yes|yEs|yeS|YEs|yES|YeS)
			;;
		*)
			if [ -z $EXIT_LINE2 ]
			then
				echo $EXIT_LINE1
			else
				echo $EXIT_LINE1
				echo $EXIT_LINE2
			fi
			exit
			;;
	esac
	unset EXIT_LINE1
	unset EXIT_LINE2
}
LINE1="The account you want to delete is $USER_ACCOUNT."
LINE2="Are you sure to delete this user? [y/n]: "
get_answer
EXIT_LINE1="You have not confirmed deleting this user or the options you output are wrong"
process_answer
#
#------------------------------------分割符----------------------------------------------------
#
#验证确认要删除的账户在/etc/passwd文件中可见，否则退出脚本
USER_ACCOUNT_RECORD=$(cat /etc/passwd | grep -w $USER_ACCOUNT)
if [ $? -eq 1 ]
then
	echo -e "\n\e[31;1mThis user does not exist\e[0m"
	exit
fi
#
#------------------------------------分割符---------------------------------------------------
#
#杀死账户进程
COMMAND_1="ps -u $USER_ACCOUNT --no-heading"
COMMAND_2="xargs -d \\n /usr/bin/sudo /bin/kill -9"

$COMMAND_1 > /dev/null
case $? in
	1)
		echo -e "\n\e[33,1mThere are no running processes for this account.\e[0m"
		;;
	0)
		LINE1="\nWhether to delete all processes of this account? [y/n]: "
		get_answer
		case $ANSWER in
			Y|y|YES|yes|Yes|yEs|yeS|YEs|yES|YeS)
				$COMMAND_1 | gawk '{print $1}' | $COMMAND_2
				echo -e "\n\e[32;1mWhether to delete all processes of this account\e[0m"
				;;
			*)
				echo -e "\n\e[33;1mYou have not confirmed deleting this user or the options you output are wrong\e[0m"
				;;
		esac
esac
#
#----------------------------------------------------------------分割符-----------------------------------------------------------------
#
#查找属于账户的文件汇总，删除用户
REPORT_DATE=$(date +%y%m%d)
REPORT_FILE=$USER_ACCOUNT"_FILE_"$REPORT_DATE".rpt"
find / -user $USER_ACCOUNT > $REPORT_FILE 2>/dev/null
userdel $USER_ACCOUNT
