#!/bin/sh
# Directory monitor
# $Id: monitor.sh,v 1.2 2009/03/03 05:33:07 tmalisie Exp $
# $Date: 2009/03/03 05:33:07 $
# $Author: tmalisie $
# $Revision: 1.2 $

#Running this inside of a screen session is great since we can then
#log it using the log writer and check status of a long job on the
#iPhone

while [ 1 -gt 0 ]; do
    NUMEVECS=`find /nfs/hn22/tmalisie/iccv09/labelme400/evecs/ -type f | wc -l`
    NUMLOCKS=`find /nfs/hn22/tmalisie/iccv09/labelme400/evecs_lock/ -type f | wc -l`
    date
    echo 'NUMEVECS: ' $NUMEVECS 'NUMLOCKS: ' $NUMLOCKS 
    sleep 30
done

#Script never finishes.. always monitors