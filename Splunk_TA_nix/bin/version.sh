#!/bin/sh
# SPDX-FileCopyrightText: 2021 Splunk, Inc. <sales@splunk.com>
# SPDX-License-Identifier: Apache-2.0

. `dirname $0`/common.sh

PRINTF='END {printf "%s %s %s %s %s %s\n", DATE, MACH_HW_NAME, MACH_ARCH_NAME, OS_REL, OS_NAME, OS_VER}'


if [ "x$KERNEL" = "xLinux" -o "x$KERNEL" = "xSunOS" -o "x$KERNEL" = "xDarwin" -o "x$KERNEL" = "xFreeBSD" ] ; then
	assertHaveCommand date
	assertHaveCommand uname
	CMD='eval date ; eval uname -m ; eval uname -r ; eval uname -s ; eval uname -v ; eval uname -p'
elif [ "x$KERNEL" = "xHP-UX" ] ; then
	# HP-UX lacks -p switch.
	assertHaveCommand date
	assertHaveCommand uname
	CMD='eval date ; eval uname -m ; eval uname -r ; eval uname -s ; eval uname -v'
elif [ "x$KERNEL" = "xAIX" ] ; then
	# AIX uses oslevel for version and release switch.
	assertHaveCommand date
	assertHaveCommand uname
	CMD='eval date ; eval uname -m ; eval oslevel -r ; eval uname -s ; eval oslevel -s'
fi

# Get the date.
PARSE_0='NR==1 {DATE=$0}'
PARSE_1='NR==2 {MACH_HW_NAME="machine_hardware_name=\"" $0 "\""}'
PARSE_2='NR==3 {OS_REL="os_release=\"" $0 "\""}'
PARSE_3='NR==4 {OS_NAME="os_name=\"" $0 "\""}'
PARSE_4='NR==5 {OS_VER="os_version=\"" $0 "\""}'
PARSE_5='NR==6 {MACH_ARCH_NAME="machine_architecture_name=\"" $0 "\""}'

MASSAGE="$PARSE_0 $PARSE_1 $PARSE_2 $PARSE_3 $PARSE_4 $PARSE_5"

$CMD | tee $TEE_DEST | $AWK "$MASSAGE $PRINTF"
echo "Cmd = [$CMD];  | $AWK '$MASSAGE $PRINTF'" >> $TEE_DEST
