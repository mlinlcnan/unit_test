#!/bin/bash
#+++++++++++++++++++++++++++++++
#Created on: 2016-3-16
#Author: mlin
#Comments: This script run on FS
#+++++++++++++++++++++++++++++++
test_vm_ip="192.168.0.81"
test_vm_user="root"
test_vm_passwd="xxxx"
test_vm_path="/root/perf"
test_vm_files="ce_sim2.tar.gz perf_gmdb_vm.sh ssh_cmd.exp scp_file.exp"
test_vm_filepkg="test_vm_filepkg.tar.gz"
test_vm_script_file="perf_gmdb_vm.sh"

server_user="root"
server_passwd="xxxx"
main_server_ip="192.168.0.71"
main_server_port="10051"
main_server_path="/root/gmdb_install"

code_ip="xxxx"
code_user="xxxx"
code_passwd="xxxx"
turing_path="~/gmdb_speed"
turing_branch="speed"
main_path="~/gmdb_main"
main_branch="Br_Dev"
tool_name="ce_sim2"
tool_pkg_dirs_new="bin/ce_sim2 3rd_lib lib"

pkg_type_now="Now"
pkg_type_main="Main"
pkg_type_turing="Turing"
work_path="$PWD"
gmdb_pkg_name_prefix="xxxx"

pkg_new_ip="xxxx"
pkg_new_user="package"
pkg_new_passwd="package"
pkg_new_path="/home2/package/release/*.tar.gz"

pkg_untar_path="gmdb_install"
pkg_gitnum_file="git_num.txt"
pkg_bk_path="gmdb_pkg_bk"

nginx_ip="xxxx"
nginx_user="root"
nginx_passwd="xxxx"
nginx_html_path="/usr/local/webserver/nginx/html"

version_file="version.properties"
default_test_model="ugw usn simple2048 simple400 simplekey2048 simplekey400" 
#simple2048 simple400 simplekey2048 simplekey400"
perf_result_file="perf_result_4ci.xml"
png_file_list="usn0_Update_CPU.PNG usn0_Update_OPS.PNG simpleX_Update_CPU.PNG simpleX_Update_OPS.PNG ugw0_Update_CPU.PNG ugw0_Update_OPS.PNG"

get_tool_from_db()
{
	#tar
	expect -f ssh_cmd.exp "$main_server_ip" "cd $main_server_path;tar zcf $tool_name.tar.gz $tool_pkg_dirs_new"  "$server_user" "$server_passwd" "60"
	#get
	expect -f scp_file.exp "get" "$main_server_ip" "$server_user" "$server_passwd" "$main_server_path/$tool_name.tar.gz" "./"
	#check
	if [ ! -f $tool_name".tar.gz" ];then
		echo "ERROR:get tool[ce_sim2] fail!"
		exit
	fi
}

deploy_test_tool()
{
	###scp file to TEST VM, first clean env###
	expect -f ssh_cmd.exp "$test_vm_ip" "rm -fr $test_vm_path;mkdir $test_vm_path;cd $test_vm_path;mkdir dmdb;killall -9 ce_sim2"  "$test_vm_user" "$test_vm_passwd" "20"
	#then tar tools and deploy on test VM
	tar zcf $test_vm_filepkg $test_vm_files
	expect -f scp_file.exp "send" "$test_vm_ip" "$test_vm_user" "$test_vm_passwd" "$test_vm_filepkg" "$test_vm_path"
	expect -f ssh_cmd.exp "$test_vm_ip" "cd $test_vm_path;tar zxf $test_vm_filepkg;tar zxf $tool_name.tar.gz -C dmdb;cp dmdb/bin/$tool_name dmdb/" "$test_vm_user" "$test_vm_passwd" "20"
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

	rm -fr $pkg_untar_path/GMDB*
	if [ "$3" = "new" ];then
		expect -f ssh_cmd.exp "$code_ip" "cd $path;git pull origin $branch;cd dmdb/build;source env.sh;./dmdb_make.py clean;rm -fr package;./dmdb_make.py prepare;./dmdb_make.py build release;./dmdb_make.py install;cp obj.gmdb/ce_sim2 ../bin/;./dmdb_make.py package;" "$code_user" "$code_passwd" "500"
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
		pkg_count=`ls -a $pkg_untar_path | grep $gmdb_pkg_name_prefix | wc -l`
		if [ $pkg_count -eq 0 ];then
			echo "ERROR:there is no pkg file in $pkg_untar_path!"
			exit
		fi
	elif [ $pkg_type = $pkg_type_main ];then
		#get pkg from [Main line]
		ready_pkg "$main_path" "$main_branch" "$3"
	elif [ $pkg_type = $pkg_type_turing ];then
		#get pkg from [Perf line]
		ready_pkg "$turing_path" "$turing_branch" "$3"
	else
		echo "ERROR:unknow pkg_type [$pkg_type]!"
		exit
	fi
	
	pkg_name_old=`ls -a $pkg_untar_path | grep $gmdb_pkg_name_prefix`
	pkg_name_part=`echo $pkg_name_old | awk -F. '{print $1}'`
	pkg_name="$pkg_name_part""_$build_type"".tar.gz"
	pkg_md5sum=`md5sum $pkg_untar_path/$pkg_name_old | awk '{print $1}'`

	###generate version.properties###
	if [ -f $pkg_untar_path/$pkg_gitnum_file ];then
		git_num=`cat $pkg_untar_path/$pkg_gitnum_file`
		cat > $version_file << EOF
build_type=$build_type
gmdb_version=$pkg_name
gmdb_md5sum=$pkg_md5sum
git_num=$git_num
EOF
	else
		echo "ERROR:there is no dir [$pkg_untar_path]!"
		exit
	fi
	cat $version_file
}

print_usage()
{
	echo "TODO!"
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
check_parameter $pkg_type "must inpt parameter 'pkg_type' [NOW|Main|Turing]!"
build_type=$2
check_parameter $build_type "must inpt parameter 'build_type' [Hand|CI|other you want]!"

###get pkg and version file ready, parameter 3 control rebuild or not###
get_ready $pkg_type $build_type $3

###deploy###
sh deployment_custom.sh

###get tool and libs from DB###
get_tool_from_db

###deploy test tools###
deploy_test_tool

###run test###
expect -f ssh_cmd.exp "$test_vm_ip" "cd $test_vm_path;./$test_vm_script_file \"$default_test_model\""  "$test_vm_user" "$test_vm_passwd" "7200"

###check result XML and send to 10.67.200.138 nginx###
check_result
