#!/bin/sh

if [ $# -ne 2 ]; then
	echo "Usage: $0 <host_list_or_listfile> <script>"
	exit
fi

if [ -f "$1" ]; then
	SERVERS=$(cat $1 | grep -v ^#)
else
	SERVERS=$1
fi

for s in ${SERVERS}; do
	echo Batchrun on ${s}
	echo "IPADDR=${s}" | cat - $2 | ssh -K -o "StrictHostKeyChecking no" -o "ConnectTimeout 3" -T root@${s} /bin/bash
	echo
done
