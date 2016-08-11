#!/bin/bash
default_test_model="imscsc_user imscsc_session"
default_test_type="I U R D"
default_vm_user="root"
default_vm_passwd="xx"
default_test_threads=10
default_test_timeout=1000
default_result_path="/root/perf/result_data"
default_xml_bkpath="$default_result_path/tmp"

test_vm_ip_list="192.168.0.81 192.168.0.82"
test_vm_path="/root/perf"
test_vm_script="multi_cesim_perf_xx_vm.sh"
test_vm_files="test_tool.tar.gz $test_vm_script ssh_cmd.exp scp_file.exp"
test_vm_files_pkg="test_vm_files_pkg.tar.gz"

server_ip_list="192.168.0.71 192.168.0.72 192.168.0.73 192.168.0.74 192.168.0.75 192.168.0.80"
#server_ip_list="192.168.0.71 192.168.0.72 192.168.0.73"
main_server_ip="192.168.0.71"
main_server_port="10051"
main_server_path="/root/xx_install"

server_count=`echo $server_ip_list | awk '{for(i=0;i<NF;i++) print $i}' | wc -l`
test_vm_count=`echo $test_vm_ip_list | awk '{for(i=0;i<NF;i++) print $i}' | wc -l`
all_test_threads=$(($test_vm_count*$default_test_threads))
run_time=`date +%Y%m%d%H%M%S`
avg_cpu_rate=0
default_test_features=$all_test_threads

code_ip="10.67.146.113"
code_user="mengl"
code_passwd="mengl"
main_path="~/xx_main"
main_branch="Br_Dev"
tool_name="test_tool"
tool_pkg_dirs_new="bin/test_tool 3rd_lib lib"

pkg_type_now="Now"
pkg_type_main="Main"
work_path="$PWD"
xx_pkg_name_prefix="xxV300R001C01"

pkg_untar_path="xx_install"
pkg_gitnum_file="git_num.txt"

nginx_ip="10.67.200.138"
nginx_user="root"
nginx_passwd="passwd"
nginx_html_path="/usr/local/webserver/nginx/html"

version_file="version.properties"
perf_result_file="perf_result_4ci.xml"
png_file_list="usn0_Update_CPU.PNG usn0_Update_OPS.PNG simpleX_Update_CPU.PNG simpleX_Update_OPS.PNG ugw0_Update_CPU.PNG ugw0_Update_OPS.PNG"

get_tool_from_db()
{
	#tar
	expect -f ssh_cmd.exp "$main_server_ip" "cd $main_server_path;tar zcf $tool_name.tar.gz $tool_pkg_dirs_new"  "$default_vm_user" "$default_vm_passwd" "60"
	#get
	expect -f scp_file.exp "get" "$main_server_ip" "$default_vm_user" "$default_vm_passwd" "$main_server_path/$tool_name.tar.gz" "./"
	#check
	if [ ! -f $tool_name".tar.gz" ];then
		echo "ERROR:get tool[test_tool] fail!"
		exit
	fi
}

deploy_test_tool()
{
	for test_vm_ip in $test_vm_ip_list
	do
		###scp file to TEST VM, first clean env###
		expect -f ssh_cmd.exp "$test_vm_ip" "rm -fr $test_vm_path;mkdir $test_vm_path;cd $test_vm_path;mkdir dmdb;killall -9 test_tool"  "$default_vm_user" "$default_vm_passwd" "20"
		#then tar tools and deploy on test VM
		tar zcf $test_vm_files_pkg $test_vm_files
		expect -f scp_file.exp "send" "$test_vm_ip" "$default_vm_user" "$default_vm_passwd" "$test_vm_files_pkg" "$test_vm_path"
		expect -f ssh_cmd.exp "$test_vm_ip" "cd $test_vm_path;tar zxf $test_vm_files_pkg;tar zxf $tool_name.tar.gz -C dmdb;cp dmdb/bin/$tool_name dmdb/" "$default_vm_user" "$default_vm_passwd" "20"
	done
}

check_result()
{
	if [ -f $perf_result_file ];then
		result_html_file=`ls -a|grep html`
		for html in $result_html_file
		do
			result_html_name="${html:0:14}"
			expect -f scp_file.exp "send" "$nginx_ip" "$nginx_user" "$nginx_passwd" "$html" "$nginx_html_path"
			expect -f ssh_cmd.exp "$nginx_ip" "cd $nginx_html_path;sed -i '15a\<a href=\"$html\"\>$result_html_name\<\/a\>\<p\>$pkg_name\<\/p\>\<hr\/\>' index.html"  "$nginx_user" "$nginx_passwd" "20"
			
			rm -fr $html
		done
		#scp PNG file,:(
		for file in $png_file_list
		do
			expect -f scp_file.exp "send" "$nginx_ip" "$nginx_user" "$nginx_passwd" "$file" "$nginx_html_path"
		done
		echo "INFO:execute success!"
	else
		echo "ERROR:there is no result XML file for CI!"
	fi
}

ready_pkg()
{
	path=$1
	branch=$2

	rm -fr $pkg_untar_path/xx*
	if [ "$3" = "new" ];then
		expect -f ssh_cmd.exp "$code_ip" "cd $path;git pull origin $branch;cd dmdb/build;source env.sh;./dmdb_make.py clean;rm -fr package;./dmdb_make.py prepare;./dmdb_make.py build release;./dmdb_make.py install;cp obj.xx/test_tool ../bin/;./dmdb_make.py package;" "$code_user" "$code_passwd" "500"
	fi
	expect -f ssh_cmd.exp "$code_ip" "cd $path;cd dmdb/build;touch package/$pkg_gitnum_file;git log|head -n 1|awk '{print \$2}' > package/$pkg_gitnum_file" "$code_user" "$code_passwd" "100"
	#get pkg and git number file
	expect -f scp_file.exp "get" "$code_ip" "$code_user" "$code_passwd" "$path/dmdb/build/package/*.tar.gz" "$pkg_untar_path"
	expect -f scp_file.exp "get" "$code_ip" "$code_user" "$code_passwd" "$path/dmdb/build/package/$pkg_gitnum_file" "$pkg_untar_path"
}

get_ready()
{
	pkg_type=$1
	build_type=$2
	pkg_name=""
	pkg_md5sum=""
	rm -fr $perf_result_file
	if [ $pkg_type = $pkg_type_now ];then
		#use now pkg
		pkg_count=`ls -a $pkg_untar_path | grep $xx_pkg_name_prefix | wc -l`
		if [ $pkg_count -eq 0 ];then
			echo "ERROR:there is no pkg file in $pkg_untar_path!"
			exit
		fi
	elif [ $pkg_type = $pkg_type_main ];then
		#get pkg from [Main line]
		ready_pkg "$main_path" "$main_branch" "$3"
	else
		echo "ERROR:unknow pkg_type [$pkg_type]!"
		exit
	fi
	
	pkg_name_old=`ls -a $pkg_untar_path | grep $xx_pkg_name_prefix`
	pkg_name_part=`echo $pkg_name_old | awk -F. '{print $1}'`
	pkg_name="$pkg_name_part""_$build_type"".tar.gz"
	pkg_md5sum=`md5sum $pkg_untar_path/$pkg_name_old | awk '{print $1}'`

	###generate version.properties###
	if [ -f $pkg_untar_path/$pkg_gitnum_file ];then
		git_num=`cat $pkg_untar_path/$pkg_gitnum_file`
		cat > $version_file << EOF
build_type=$build_type
xx_version=$pkg_name
xx_md5sum=$pkg_md5sum
git_num=$git_num
EOF
	else
		echo "ERROR:there is no dir [$pkg_untar_path]!"
		exit
	fi
	cat $version_file
}

calculate_cpu()
{
	cpu_file_names=$1
	cpu_file_list=`ls -a $default_result_path | grep $cpu_file_names | grep cpu`
	cpu_file_count=`ls -a $default_result_path | grep $cpu_file_names | grep cpu | wc -l`
	cpu_avg=0
	cpu_sum=0
	if [ "X""$cpu_file_list" != "X" ];then
		for cpu_file in $cpu_file_list
		do
			one_sum=`cat $default_result_path/$cpu_file | awk '{print $2+$4}' | awk '$1 > 20' | awk '{sum += $1};END {print sum}'`
			one_count=`cat $default_result_path/$cpu_file | awk '{print $2+$4}' | awk '$1 > 20' | wc -l`
			one_avg=`echo $one_sum/\($one_count\) | bc`
			echo "++++++++++++++++++++++++++++++[$cpu_file][CPU:$one_avg]++++++++++++++++++++++++++++++"
			if [ "X" = "X"$one_avg ];then
				one_avg=0
			fi
			cpu_sum=$(($cpu_sum+$one_avg))
		done
		cpu_avg=$(($cpu_sum/$cpu_file_count))
		avg_cpu_rate=$cpu_avg
	else
		echo "ERROR:There are no CPU files!"
	fi
}

run_test_control_model()
{
	run_test_model=$1
	if [ "X" = "X""$run_test_model" ];then
		run_test_model="$default_test_model"
		echo "INFO:doesn't input test model,so use default test model[$default_test_model]"
		sleep 2
	fi
	
	for model in $run_test_model
	do
		field_len=0
		case "$model" in
			"simple400")
			model="simple"
			field_len=400
			test_type="$default_test_type"
			test_users=3000000
			;;
			*)
			echo "ERROR:doesn't support [$model]!"
			continue
			;;
		esac
		
		#every model,every type
		run_test_control_type "$model" "$field_len" "$test_type" "$test_users"
	done
}

run_get_xml_from_testvm()
{
	base_file=$1
	declare -i worker_id=0
	for test_vm_ip in $test_vm_ip_list
	do
		expect -f scp_file.exp "get" "$test_vm_ip" "$default_vm_user" "$default_vm_passwd" "$test_vm_path/dmdb/$base_file""w""$worker_id.xml" "$default_result_path" >> /dev/null
		let worker_id++
	done
}

run_test_control_type()
{
	model=$1
	field_len=$2
	run_test_type=$3
	test_users=$4
	
	#create table
	first_test_vm_ip=`echo $test_vm_ip_list | awk '{print $1}'`
	expect -f ssh_cmd.exp "$first_test_vm_ip" "cd $test_vm_path;./$test_vm_script create_table $model $field_len" "$default_vm_user" "$default_vm_passwd" "120"
	
	#run
	for type in $run_test_type
	do
		#base_file=$model"_b"$field_len"_"$type"_w"$worker_id
		base_file=$model"_b"$field_len"_"$type"_"
		
		#start monitor CPU,first monitor 2*10=20s
		for server_ip in $server_ip_list
		do
			expect -f ssh_cmd.exp "$server_ip" "top -d 2 -bn 10 | grep Cpu > $base_file$server_ip.cpu &"  "$default_vm_user" "$default_vm_passwd" "3" >> /dev/null
		done
		
		#start run test_tool
		declare -i worker_id=0
		for test_vm_ip in $test_vm_ip_list
		do
			expect -f ssh_cmd.exp "$test_vm_ip" "cd $test_vm_path;./$test_vm_script run $model $field_len $test_users $worker_id $default_test_features $default_test_threads $all_test_threads $type &" "$default_vm_user" "$default_vm_passwd" "2"
			let worker_id++
		done
		
		#monitor CPU and check result
		sleep 20
		wait_time=20
		run_test_complete_count=0
		while [ "X" = "X" ]
		do
			#check result
			run_test_complete_count=`ls -al $default_result_path| grep $base_file | grep -v 'grep' | wc -l`
			if [ "$run_test_complete_count" = "$test_vm_count" ];then
				echo -e "\033[33mINFO:wait[$wait_time s][complete_count:$run_test_complete_count]...\033[0m"
				echo -e "\033[33mINFO:all run complete!\033[0m"
				break;
			else
				echo -e "\033[33mINFO:wait[$wait_time s][complete_count:$run_test_complete_count]...\033[0m"
			fi
			
			if [ $wait_time -gt $default_test_timeout ];then
				echo "ERROR:Run [$model][$type] timeout :("
				break;
			else
				#moniter CPU,10s
				for server_ip in $server_ip_list
				do
					expect -f ssh_cmd.exp "$server_ip" "top -d 2 -bn 5 | grep Cpu >> $base_file$server_ip.cpu &"  "$default_vm_user" "$default_vm_passwd" "3" >> /dev/null
				done
				sleep 10
				wait_time=$(($wait_time+10))
			fi
			#try get from test VM
			run_get_xml_from_testvm $base_file
		done
		
		#get cpu file and calculate
		if [ $test_time -lt $test_timeout ];then
			for server_ip in $server_ip_list
			do
				expect -f scp_file.exp "get" "$server_ip" "$default_vm_user" "$default_vm_passwd" "$base_file$server_ip.cpu" "$default_result_path"
			done
			
			#calculate CPU
			calculate_cpu "$base_file"
			
			#handle xml file
			xml_file_list=`ls -a $default_result_path | grep xml | grep $base_file`
			xml_file_path=""
			for xml_file in $xml_file_list
			do
				xml_file_path="$xml_file_path"" $default_result_path/$xml_file"
				sed -i "s/build_id=\"0\"/build_id=\"$run_time\"/g" $default_result_path/$xml_file
				sed -i "s/num_dn=\"0\"/num_dn=\"$server_count\"/g" $default_result_path/$xml_file
				sed -i "s/data_model=\"0\"/data_model=\"$model$field_len\"/g" $default_result_path/$xml_file
				sed -i "s/events_type=\"0\"/events_type=\"$type\"/g" $default_result_path/$xml_file
				sed -i "s/cpu=\"0\"/cpu=\"$avg_cpu_rate\"/g" $default_result_path/$xml_file
			done
			avg_cpu_rate=0
			
			#store result to DB
			java -jar perf_report.jar -s $xml_file_path
			
			#move to tmp dir
			mv $xml_file_path $default_xml_bkpath
			mv $default_result_path/*cpu $default_xml_bkpath
		fi
	done
}

print_usage()
{
	echo "The first parameter is [package type],second is [build type],third is [test model]"
}

check_parameter()
{
	if [ "X" = "$1""X" ];then
		echo "ERROR:$2!"
		print_usage
		exit
	fi
}

######main######
###get pkg###
pkg_type=$1
check_parameter $pkg_type "must input parameter 'pkg_type' [Now|Main]!"
build_type=$2
check_parameter $build_type "must input parameter 'build_type' [Hand|CI|other you want]!"

###get pkg and version file ready, the third parameter control rebuild xx or not###
get_ready $pkg_type $build_type $3

###deploy###
sh deployment_custom.sh

###get tool and libs from DB VM###
get_tool_from_db

###deploy test tool to Test VM###
deploy_test_tool

###run test###
input_test_mode=$4
run_test_control_model $input_test_mode

###generate XML and PNG
java -jar perf_report.jar -g $run_time

###check result XML and send to 10.67.200.138 nginx###
#check_result
