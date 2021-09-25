#!/bin/sh
# SPDX-FileCopyrightText: 2021 Splunk, Inc. <sales@splunk.com>
# SPDX-License-Identifier: Apache-2.0

. `dirname $0`/common.sh

HEADER='USERNAME                        FROM                            LATEST'
HEADERIZE="BEGIN {print \"$HEADER\"}"
PRINTF='{printf "%-30s  %-30.30s  %-s\n", username, from, latest}'

if [ "x$KERNEL" = "xLinux" ] ; then
	CMD='last -iw'
	FILTER='{if ($0 == "") exit; if ($1 ~ /reboot|shutdown/ || $1 in users) next; users[$1]=1}'
	FORMAT='{username = $1; from = (NF==10) ? $3 : "<console>"; latest = $(NF-6) " " $(NF-5) " " $(NF-4) " " $(NF-3)}'
elif [ "x$KERNEL" = "xSunOS" ] ; then
	CMD='last -n 999'
	FILTER='{if ($0 == "") exit; if ($1 ~ /reboot|shutdown/ || $1 in users) next; users[$1]=1}'
	FORMAT='{username = $1; from = (NF==10) ? $3 : "<console>"; latest = $(NF-6) " " $(NF-5) " " $(NF-4) " " $(NF-3)}'
elif [ "x$KERNEL" = "xAIX" ] ; then
	failUnsupportedScript
elif [ "x$KERNEL" = "xDarwin" ] ; then
	CMD='last -99'
	FILTER='{if ($0 == "") exit; if ($1 ~ /reboot|shutdown/ || $1 in users) next; users[$1]=1}'
	FORMAT='{username = $1; from = ($0 !~ /                /) ? $3 : "<console>"; latest = $(NF-6) " " $(NF-5) " " $(NF-4) " " $(NF-3)}'
elif [ "x$KERNEL" = "xHP-UX" ] ; then
    CMD='lastb -Rx'
    FORMAT='{username = $1; from = ($2=="console") ? $2 : $3; latest = $(NF-3) " " $(NF-2)" " $(NF-1)}' 
    FILTER='{if ($1 == "BTMPS_FILE") next; if (NF==0) next; if (NF<=6) next;}'
elif [ "x$KERNEL" = "xFreeBSD" ] ; then
	CMD='lastlogin'
	FORMAT='{username = $1; from = (NF==8) ? $3 : "<console>"; latest=$(NF-4) " " $(NF-3) " " $(NF-2) " " $(NF-1) " " $NF}'
fi

assertHaveCommand $CMD

out=`$CMD | tee $TEE_DEST | $AWK "$HEADERIZE $FILTER $FORMAT $PRINTF"  header="$HEADER"`
lines=`echo "$out" | wc -l`
if [ $lines -gt 1 ]; then
	echo "$out"
	echo "Cmd = [$CMD];  | $AWK '$HEADERIZE $FILTER $FORMAT $PRINTF' header=\"$HEADER\"" >> $TEE_DEST
else
	echo "No data is present" >> $TEE_DEST
fi