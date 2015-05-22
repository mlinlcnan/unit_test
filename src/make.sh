#!/bin/bash

dirs=`ls -F|grep '/$'`

for dir in $dirs
do
	cd $dir
	echo "**start make $dir**"
	make clean
	make
	if [ $? -eq 0 ];then
		echo "**make $dir success!"
		cp *.o ../../obj
	else
		echo "**make $dir fail!"
	fi
	cd -
	echo "--------------------------"
done
