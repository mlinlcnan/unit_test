#!/bin/bash
default_test_timeout=1000
script_log="$0.log"

main_server_ip="192.168.0.71"
main_server_port="10051"
tool_name="test_tool"
tool_home="/root/perf/dmdb"

#FS information
fs_ip="192.168.0.2"
fs_user="root"
fs_passwd="huawei_123"
fs_work_path="/root/perf"
fs_data_path="/root/perf/result_data"


set_env()
{
	export TOOL_HOME=$tool_home
	export LD_LIBRARY_PATH=${TOOL_HOME}/3rd_lib/boost:${LD_LIBRARY_PATH}
	export LD_LIBRARY_PATH=${TOOL_HOME}/3rd_lib/protobuf:${LD_LIBRARY_PATH}
	export LD_LIBRARY_PATH=${TOOL_HOME}/3rd_lib/jansson:${LD_LIBRARY_PATH}
	export LD_LIBRARY_PATH=${TOOL_HOME}/3rd_lib/hwsecurec:${LD_LIBRARY_PATH}
	export LD_LIBRARY_PATH=${TOOL_HOME}/lib:${LD_LIBRARY_PATH}
}

run()
{
	test_model=$1
	field_len=$2
	test_users=$3
	worker_id=$4
	test_features=$5
	test_threads=$6
	all_test_threads=$7
	type=$8
	
	set_env
	
	base_file=$test_model"_b"$field_len"_"$type"_w"$worker_id
	result_file=$base_file".xml"
	log_file=$base_file".log"
	sn_flag=""
	
	if [ "$test_model" = "ugw" ];then
		#usn and ugw model hava S&N
		sn_flag="-N S"
	fi
	
	#clean env
	rm -fr $result_file $log_file
	
	#run test
	fail_count=0
	test_time=0
	run_flag="X"
	while [ "$run_flag" = "X" ]
	do
		fail_line=0
		rm -fr $log_file
			
		./$tool_name -W $test_model -z bench -l tcp:host=$main_server_ip,port=$main_server_port -d $test_features -n $all_test_threads -t $test_threads -w $worker_id -u $test_users -e $type -o ./$result_file -X -A -L 2 -Q 10 -b $field_len $sn_flag > $log_file &
		if [ $? -ne 0 ];then
			echo "ERROR:execute test_tool fail!" >> $script_log
			break;
		fi
			
		sleep 3
		test_time=$(($test_time+3))
		#first check process exist,connection error will exit
		fail_line=`cat $log_file | grep -E 'service not available|usage:' | wc -l`
		if [ $fail_line -ge 1 ];then
			fail_info=`cat $log_file | grep -E 'service not available|usage:'`
			echo "ERROR:execute test_tool test fail:$fail_info" >> $script_log
		fi
		
		#then check,test_tool maybe random failure!!
		fail_line=`cat $log_file | grep -E 'Worker|STATUS|, 0 events' | wc -l`
		if [ $fail_line -gt 1 ];then
			fail_count=$(($fail_count+1))
			if [ $test_time -gt $default_test_timeout ];then
				echo "ERROR:Run [$test_model][$type] timeout :(" >> $script_log
				run_flag="success"
				break;
			else
				echo "ERROR:Run [$test_model][$type] fail [$fail_count] :(" >> $script_log
			fi
			killall -9 $tool_name
		else
			echo "INFO:Run [$test_model][$type] success :)" >> $script_log
			run_flag="success"
			break;
		fi
	done
	
	#run success,then wait complete
	while [ "X" = "X" ]
	do
		if [ -f $result_file ];then
			echo "INFO:Run [$test_model][$type] complete." >> $script_log
			cat $log_file
			break;
		fi
		sleep 5
		test_time=$(($test_time+5))
		if [ $test_time -gt $default_test_timeout ];then
			echo "ERROR:Run [$test_model][$type] timeout :(" >> $script_log
			killall -9 $tool_name
			break;
		fi
		echo "INFO:Wait test complete [$test_time s]..." >> $script_log
	done
			
	#send result file to FS
	if [ $test_time -lt $default_test_timeout ];then
		expect -f ../scp_file.exp "send" "$fs_ip" "$fs_user" "$fs_passwd" "$result_file" "$fs_data_path"
	fi
}

create_table()
{
	data_model=$1
	field_len=$2
	
	#set env
	set_env
	
	#execute create table
	./$tool_name -W $data_model -z bench -l tcp:host=$main_server_ip,port=$main_server_port -c -I h -b $field_len
	if [ $? -ne 0 ];then
		echo -e "\033[33mERROR:execute test_tool to create table fail!\033[0m"
	fi
}

###main###
option=$1
input_data_model=$2
input_field_len=$3

echo "INFO:data_model[$input_data_model],field_len[$input_field_len]."
cd $tool_home
rm -fr $script_log
case "$option" in
	"create_table")
	create_table $input_data_model $input_field_len
	;;
	"run")
	input_test_users=$4
	input_worker_id=$5
	input_test_features=$6
	input_test_threads=$7
	input_all_test_threads=$8
	input_type=$9
	echo "INFO:test_users[$input_test_users],worker_id[$input_worker_id],test_features[$input_test_features],test_threads[$input_test_threads],all_test_threads[$input_all_test_threads],type[$input_type]" 
	
	run $input_data_model $input_field_len $input_test_users $input_worker_id $input_test_features $input_test_threads $input_all_test_threads $input_type
	;;
	"*")
	echo "ERROR:don't support option[$option]!"
	;;
esac
