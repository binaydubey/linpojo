#!/bin/sh
# SPDX-FileCopyrightText: 2021 Splunk, Inc. <sales@splunk.com>
# SPDX-License-Identifier: Apache-2.0

. `dirname $0`/common.sh

queryHaveCommand ntpdate
FOUND_NTPDATE=$?

#With ntpdate
if [ $FOUND_NTPDATE -eq 0 ] ; then
	echo "Found ntpdate command" >> $TEE_DEST
	if [ -f    /etc/ntp.conf ] ; then         # Linux; FreeBSD; AIX; Mac OS X maybe
		CONFIG=/etc/ntp.conf
	elif [ -f  /etc/inet/ntp.conf ] ; then    # Solaris
		CONFIG=/etc/inet/ntp.conf
	elif [ -f  /private/etc/ntp.conf ] ; then # Mac OS X
		CONFIG=/private/etc/ntp.conf
	else
		CONFIG=
	fi

	SERVER_DEFAULT='0.pool.ntp.org'
	if [ "x$CONFIG" = "x" ] ; then
		SERVER=$SERVER_DEFAULT
	else
		SERVER=`$AWK '/^server / {print $2; exit}' $CONFIG`
		SERVER=${SERVER:-$SERVER_DEFAULT}
	fi

	CMD2="ntpdate -q $SERVER"
	echo "CONFIG=$CONFIG, SERVER=$SERVER" >> $TEE_DEST

#With Chrony
else
	CMD2="chronyc -n sources"
fi

CMD1='date'

assertHaveCommand $CMD1
assertHaveCommand $CMD2

$CMD1 | tee -a $TEE_DEST
echo "Cmd1 = [$CMD1]" >> $TEE_DEST

$CMD2 | tee -a $TEE_DEST
echo "Cmd2 = [$CMD2]" >> $TEE_DEST
