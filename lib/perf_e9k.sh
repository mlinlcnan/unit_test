#!/bin/bash
#+++++++++++++++++++++++++++++++
#Created on: 2016-3-16
#Author: mlin
#Comments: This script run on Test VM,change for E9000
#+++++++++++++++++++++++++++++++

server_ip_list="48.10.46.71 48.10.46.72"
server_count=2
server_user="root"
server_passwd="huawei@123"
main_server_ip="48.10.46.71"
main_server_port="10051"

#ce_sim2
tool_name="ce_sim2"
tool_home="/root/perf/dmdb"

#ce_sim2 run parameters
default_test_type="I U R D"
test_users=3000000
test_features=48
test_threads=16
test_timeout=1200
test_queue_size=10

top_delay=2
top_count=10

#FS
fs_ip="48.29.19.1"
fs_user="root"
fs_passwd="Huawei@CLOUD8!"
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

calculate_cpu()
{
	cpu_file_names=$1
	result_file=$2
	cpu_file_list=`ls -a | grep $cpu_file_names | grep cpu`
	cpu_file_count=`ls -a | grep $cpu_file_names | grep cpu | wc -l`
	cpu_avg=0
	cpu_sum=0
	if [ "X""$cpu_file_list" != "X" ];then
		for cpu_file in $cpu_file_list
		do
			one_sum=`cat $cpu_file | awk '{print $2+$4}' | awk '$1 > 10' | awk '{sum += $1};END {print sum}'`
			one_count=`cat $cpu_file | awk '{print $2+$4}' | awk '$1 > 10' | wc -l`
			one_avg=`echo $one_sum/\($one_count\) | bc`
			echo "++++++++++++++++++++++++++++++[$cpu_file][CPU:$one_avg]++++++++++++++++++++++++++++++"
			if [ "X""$one_avg" = "X" ];then
				one_avg=0
			fi
			cpu_sum=$(($cpu_sum+$one_avg))
		done
		cpu_avg=$(($cpu_sum/$cpu_file_count))
		sed -i "s/cpu=\"0\"/cpu=\"$cpu_avg\"/g" $result_file
	else
		echo "ERROR:There are no CPU files!"
	fi
}

run_test()
{
	test_model=$1
	field_len=$2
	run_test_type=$3
	data_file=$test_model"_"$test_users

	set_env
	
	#create table
	./$tool_name -W $test_model -z bench -l tcp:host=$main_server_ip,port=$main_server_port -c -I h -b $field_len
	if [ $? -ne 0 ];then
		echo "ERROR:execute ce_sim2 to create table fail!"
		return
	fi
	
	#execute
	for type in $run_test_type
	do
		base_file=$test_model"_b"$field_len"_"$type
		result_file=$base_file".xml"
		log_file=$base_file".log"
		perf_data=$base_file".data"
		sn_flag=""
		
		if [ "$test_model" = "usn" -o "$test_model" = "ugw" ];then
			#usn and ugw model hava S&N
			sn_flag=" -N S"
		fi
		
		#clean env
		rm -fr $result_file $log_file 
		
		#run test
		fail_count=0
		test_time=0
		while [ "X" = "X" ]
		do
			fail_line=0
			rm -fr $log_file
			
			./$tool_name -W $test_model -z bench -l tcp:host=$main_server_ip,port=$main_server_port -d $test_features -n $test_threads -t $test_threads -u $test_users -e $type -o ./$result_file -X -A -L 2 -Q $test_queue_size -b $field_len $sn_flag > $log_file &
			if [ $? -ne 0 ];then
				echo "ERROR:execute ce_sim2 fail!"
				break;
			fi
			
			sleep 3
			#first check process exist--connection error will exit
			fail_line=`cat $log_file | grep -E 'service not available|usage:' | wc -l`
			if [ $fail_line -ge 1 ];then
				fail_info=`cat $log_file | grep -E 'service not available|usage:'`
				echo "ERROR:execute ce_sim2 test fail:$fail_info"
			fi
			
			#check--!!it's ce_sim2 bug!!
			fail_line=`cat $log_file | grep -E 'Worker|STATUS|, 0 events' | wc -l`
			if [ $fail_line -gt 1 ];then
				fail_count=$(($fail_count+1))
				test_time=$(($test_time+3))
				if [ $test_time -gt $test_timeout ];then
					echo "ERROR:Run [$test_model][$type] timeout :("
					killall -9 $tool_name
					break;
				else
					echo "ERROR:Run [$test_model][$type] fail [$fail_count] :("
					killall -9 $tool_name
					continue
				fi
			fi
			
			#run success,first monitor remote server CPU
			echo "++++++++++++++++++++++++++++++++++++++++++++++++"
			echo "INFO:Run test tool success."
			echo "$tool_name -W $test_model -z bench -l tcp:host=$main_server_ip,port=$main_server_port -d $test_features -n $test_threads -t $test_threads -u $test_users -e $type -f ./$data_file -o ./$result_file -X -A -L 2 -Q $test_queue_size -b $field_len $sn_flag"
			echo "++++++++++++++++++++++++++++++++++++++++++++++++"
			sleep 2
			for ip in $server_ip_list
			do
				#there will use ($top_count-1)*$top_delay seconds
				expect -f ../ssh_cmd.exp "$ip" "top -d $top_delay -bn $top_count | grep Cpu > $base_file$ip.cpu &"  "$server_user" "$server_passwd" "10"
			done
			
			#then wait complete
			sleep 20
			test_time=20
			while [ "X" = "X" ]
			do
				if [ -f $result_file ];then
					echo "INFO:Run [$test_model][$type] complete."
					cat $log_file
					break;
				fi
				sleep 5
				test_time=$(($test_time+5))
				if [ $test_time -gt $test_timeout ];then
					echo "ERROR:Run [$test_model][$type] timeout :("
					killall -9 $tool_name
					break;
				fi
				echo "INFO:Wait test complete [$test_time s]."
			done
			
			#run completed and not timeout
			if [ $test_time -lt $test_timeout ];then
				#get CPU info
				for ip in $server_ip_list
				do
					expect -f ../scp_file.exp "get" "$ip" "$server_user" "$server_passwd" "$base_file$ip.cpu" "./"
				done
				
				#calculate CPU
				calculate_cpu "$base_file" "$result_file"
				
				#change result xml file
				sed -i "s/build_id=\"0\"/build_id=\"$run_time\"/g" $result_file
				sed -i "s/num_dn=\"0\"/num_dn=\"$server_count\"/g" $result_file
				sed -i "s/data_model=\"0\"/data_model=\"$test_model$field_len\"/g" $result_file
				sed -i "s/events_type=\"0\"/events_type=\"$type\"/g" $result_file
				
				echo "++++++++++++++++++++++++++++++++++++++++++++++++"
				cat $result_file
				echo "++++++++++++++++++++++++++++++++++++++++++++++++"
			fi
			break;
		done
	done
	
	#backup data
	rm -fr $data_file
	tar_files=$test_model"_b"$field_len
	tar_pkg_name=$run_time"_"$test_model"_b"$field_len"databk.tar.gz"
	tar zcf $tar_pkg_name $tar_files*
	#send tar file to FS
	expect -f ../scp_file.exp "send" "$fs_ip" "$fs_user" "$fs_passwd" "$tar_pkg_name" "$fs_data_path"
}

check_parameter()
{
	if [ "X" = "$1""X" ];then
		echo "ERROR:$2!"
		exit
	fi
}

###main###
test_model=$1
check_parameter "$test_model" "must input test model!"

if [ ! -d $tool_home ];then
	echo "INFO:there is no test tool!"
	get_cesim_from_fs
fi

cd $tool_home
#the run_time is build_id
run_time=`date +%Y%m%d%H%M%S`

#test type
test_type="$default_test_type"

#run test
for model in $test_model
do
	field_len=0
	case "$model" in
		"simple400")
		model="simple"
		field_len=400
		test_type="$default_test_type"
		test_users=3000000
		;;
		"simple2048")
		model="simple"
		field_len=2048
		test_type="$default_test_type"
		test_users=3000000
		;;
		"simplekey400")
		model="simplekey"
		field_len=400
		test_type="$default_test_type"
		test_users=3000000
		;;
		"simplekey2048")
		model="simplekey"
		field_len=2048
		test_type="$default_test_type"
		test_users=3000000
		;;
		"usn")
		test_type="I A U R D"
		field_len=0
		test_users=600000
		;;
		"ugw")
		test_type="I A U R D"
		field_len=0
		test_users=2000000
		;;
		*)
		echo "ERROR:doesn't support [$model]!"
		exit
		;;
	esac
	
	run_test "$model" "$field_len" "$test_type"	
done

echo "INFO:run all testcases complete!"
