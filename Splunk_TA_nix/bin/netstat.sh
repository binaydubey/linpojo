#!/bin/sh
# SPDX-FileCopyrightText: 2021 Splunk, Inc. <sales@splunk.com>
# SPDX-License-Identifier: Apache-2.0

. `dirname $0`/common.sh

HEADER='Proto  Recv-Q  Send-Q  LocalAddress                    ForeignAddress                  State'
HEADERIZE="BEGIN {print \"$HEADER\"}"
PRINTF='{printf "%-5s  %6s  %6s  %-30.30s  %-30.30s  %-s\n", $1, $2, $3, $4, $5, $6}'
FILL_BLANKS='($1=="udp") {$6="<n/a>"}'

if [ "x$KERNEL" = "xLinux" ] ; then
	queryHaveCommand ss
	FOUND_SS=$?
	if [ $FOUND_SS -eq 0 ] ; then
		CMD='eval ss -antu 2>/dev/null | egrep "tcp|udp"'
		FORMAT='{ state=$2; $2=$3; $3=$4; $4=$5; $5=$6; $6=state}'
	else
		CMD='eval netstat -aenp 2>/dev/null | egrep "tcp|udp"'
	fi
elif [ "x$KERNEL" = "xSunOS" ] ; then
	CMD='netstat -an -f inet -f inet6'
	FIGURE_SECTION='NR==1 {inUDP=1;inTCP=0} /^TCP: IPv/ {inUDP=0;inTCP=1} /^SCTP:/ {exit}'
	FILTER='/: IPv|Local Address|^$|^-----/ {next}'
	FORMAT_UDP='(inUDP) {localAddr=$1; $1="udp"; $2=$3=0; $4=localAddr; $5="*.*"}'
	FORMAT_TCP='(inTCP) {localAddr=$1; foreignAddr=$2; sendQ=$4; recvQ=$6; state=$7; $1="tcp"; $2=recvQ; $3=sendQ; $4=localAddr; $5=foreignAddr; $6=state}'
	FORMAT="$FORMAT_UDP $FORMAT_TCP"
elif [ "x$KERNEL" = "xAIX" ] ; then
	CMD='eval netstat -an 2>/dev/null | egrep "tcp|udp"'
elif [ "x$KERNEL" = "xDarwin" ] ; then
	CMD='eval netstat -anW | egrep "tcp|udp"'
	FORMAT='{gsub("[46]", "", $1)}'
elif [ "x$KERNEL" = "xHP-UX" ] ; then
    CMD='eval netstat -an | egrep "tcp|udp"'
elif [ "x$KERNEL" = "xFreeBSD" ] ; then
	CMD='eval netstat -an | egrep "tcp|udp"'
	FORMAT='{gsub("[46]", "", $1)}'
fi

assertHaveCommand $CMD
$CMD | tee $TEE_DEST | $AWK "$HEADERIZE $FIGURE_SECTION $FILTER $FORMAT $FILL_BLANKS $PRINTF"  header="$HEADER"
echo "Cmd = [$CMD];  | $AWK '$HEADERIZE $FIGURE_SECTION $FILTER $FORMAT $FILL_BLANKS $PRINTF' header=\"$HEADER\"" >> $TEE_DEST
