#!/bin/sh
# SPDX-FileCopyrightText: 2021 Splunk, Inc. <sales@splunk.com>
# SPDX-License-Identifier: Apache-2.0
#
# credit for improvement to http://splunk-base.splunk.com/answers/41391/rlogsh-using-too-much-cpu
. `dirname $0`/common.sh

OLD_SEEK_FILE=$SPLUNK_HOME/var/run/splunk/unix_audit_seekfile # For handling upgrade scenarios
CURRENT_AUDIT_FILE=/var/log/audit/audit.log # For handling upgrade scenarios
SEEK_FILE=$SPLUNK_HOME/var/run/splunk/unix_audit_seektime
AUDIT_FILE=/var/log/audit/audit.log*

if [ "x$KERNEL" = "xLinux" ] ; then
    assertInvokerIsSuperuser
    assertHaveCommand service
    assertHaveCommandGivenPath /sbin/ausearch
    if [ -n "`service auditd status 2>/dev/null`" -a "$?" -eq 0 ] ; then
            CURRENT_TIME=$(date --date="1 seconds ago" +"%m/%d/%Y %T") # 1 second ago to avoid data loss

            if [ -e $SEEK_FILE ] ; then
                SEEK_TIME=`head -1 $SEEK_FILE`
                awk " { print } " $AUDIT_FILE | /sbin/ausearch -i -ts $SEEK_TIME -te $CURRENT_TIME | grep -v "^----" 

            elif [ -e $OLD_SEEK_FILE ] ; then
                rm -rf $OLD_SEEK_FILE # remove previous checkpoint
                # start ingesting from the first entry of current audit file                
                awk ' { print } ' $CURRENT_AUDIT_FILE | /sbin/ausearch -i -te $CURRENT_TIME | grep -v "^----"
            
            else
                # no checkpoint found
                awk " { print } " $AUDIT_FILE | /sbin/ausearch -i  -te $CURRENT_TIME | grep -v "^----"
            fi
            echo "$CURRENT_TIME" > $SEEK_FILE # Checkpoint+
    
    elif [ "`service auditd status`" -a ] ; then    # Added this condition to get error logs
        :
    fi
elif [ "x$KERNEL" = "xSunOS" ] ; then
    :
elif [ "x$KERNEL" = "xDarwin" ] ; then
    :
elif [ "x$KERNEL" = "xHP-UX" ] ; then
	:
elif [ "x$KERNEL" = "xFreeBSD" ] ; then
	:
fi
