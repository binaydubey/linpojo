#!/bin/sh
# SPDX-FileCopyrightText: 2021 Splunk, Inc. <sales@splunk.com>
# SPDX-License-Identifier: Apache-2.0

# a similar effect can be accomplished with: "nc -z 127.0.0.1 1-32768", and "nc -zu 127.0.0.1 1-32768"

. `dirname $0`/common.sh

HEADER='Proto   Port'
HEADERIZE="BEGIN {print \"$HEADER\"}"
PRINTF='{printf "%-5s  %5d\n", proto, port}'
FILTER_INACTIVE='($NF ~ /^CLOSE/) {next}'

if [ "x$KERNEL" = "xLinux" ] ; then
	queryHaveCommand ss
	FOUND_SS=$?
	if [ $FOUND_SS -eq 0 ] ; then
		CMD='eval ss -lnut | egrep "^tcp|^udp"'
		FORMAT='{proto=$1; sub("^.*:", "", $5); port=$5}'
	else
		CMD='eval netstat -ln | egrep "^tcp|^udp"'
		FORMAT='{proto=$1; sub("^.*:", "", $4); port=$4}'
	fi
elif [ "x$KERNEL" = "xSunOS" ] ; then
	CMD='netstat -an -f inet -f inet6'
	FIGURE_SECTION='BEGIN {inUDP=1;inTCP=0} /^TCP: IPv/ {inUDP=0;inTCP=1} /^SCTP:/ {exit}'
	FILTER='/: IPv|Local Address|^$|^-----/ {next} (! port) {next}'
	FORMAT='{if (inUDP) proto="udp"; if (inTCP) proto="tcp"; sub("^.*[^0-9]", "", $1); port=$1}'
elif [ "x$KERNEL" = "xAIX" ] ; then
	CMD='eval netstat -an | egrep "^tcp|^udp"'
	HEADERIZE="BEGIN {print \"$HEADER\"}"
	FORMAT='{gsub("[46]", "", $1); proto=$1; sub("^.*[^0-9]", "", $4); port=$4}'
	FILTER='{if ($4 == "") next}'
elif [ "x$KERNEL" = "xDarwin" ] ; then
	CMD='eval netstat -ln | egrep "^tcp|^udp"'
	HEADERIZE="BEGIN {print \"$HEADER\"}"
	FORMAT='{gsub("[46]", "", $1); proto=$1; sub("^.*[^0-9]", "", $4); port=$4}'
	FILTER='{if ($4 == "") next}'
elif [ "x$KERNEL" = "xHP-UX" ] ; then
    CMD='eval netstat -an | egrep "^tcp|^udp"'
    HEADERIZE="BEGIN {print \"$HEADER\"}"
    FORMAT='{gsub("[46]", "", $1); proto=$1; sub("^.*[^0-9]", "", $4); port=$4}'
    FILTER='{if ($4 == "") next}'
elif [ "x$KERNEL" = "xFreeBSD" ] ; then
	CMD='eval netstat -ln | egrep "^tcp|^udp"'
	HEADERIZE="BEGIN {print \"$HEADER\"}"
	FORMAT='{gsub("[46]", "", $1); proto=$1; sub("^.*[^0-9]", "", $4); port=$4}'
fi

assertHaveCommand $CMD
$CMD | tee $TEE_DEST | $AWK "$HEADERIZE $FIGURE_SECTION $FORMAT $FILTER $FILTER_INACTIVE $PRINTF"  header="$HEADER"
echo "Cmd = [$CMD];  | $AWK '$HEADERIZE $FIGURE_SECTION $FORMAT $FILTER $FILTER_INACTIVE $PRINTF' header=\"$HEADER\"" >> $TEE_DEST
