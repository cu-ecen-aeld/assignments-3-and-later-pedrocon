#!/bin/sh

set -e
set -u


searchstr=AELD_IS_FUN
filesdir=/tmp/aeld-data

if [ $# -lt 2 ]
then
	echo "Invalid number of variables specified. This script requires 2 input parameters.\nParameter 1: Directory path. Parameter 2: Search String."
	exit 1
else
	if [ -d "$1" ]
	then
		filesdir=$1
		searchstr=$2		
	else
		echo "$1 does not exist."
		exit 1
	fi
fi

X=`find $filesdir -type f | wc -l`
Y=`grep -ro $searchstr $filesdir | wc -l | xargs`


echo "The number of files are $X and the number of matching lines are $Y"
exit 0

