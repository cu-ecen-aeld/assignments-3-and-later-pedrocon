#!/bin/sh

#set -e
#set -u

dirtofile=`dirname $1`
if [ $# -lt 2 ]
then
	echo "Invalid number of variables specified. This script requires 2 input parameters.\nParameter 1: Directory path including file name. Parameter 2: String to write to file specified in parameter 1."
	exit 1
else
	if [ ! -d "$dirtofile" ]
	then
		mkdir -p $dirtofile
	fi
	echo $2 > $1
fi

exit 0

