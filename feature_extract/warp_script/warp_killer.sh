#!/bin/sh

# A script to kill/list my WARP jobs -- probably something from the DDIP pipeline
# hacked up by Tomasz Malisiewicz (tomasz@cmu.edu)
# Run like: ./warp_killer.sh
# This will list possible jobs
# Run like: ./warp_killer.sh recognize_me
# This will kill all instances of job recognize_me

# $Id: warp_killer.sh,v 1.2 2009/02/28 09:10:40 tmalisie Exp $
# $Date: 2009/02/28 09:10:40 $
# $Author: tmalisie $
# $Revision: 1.2 $

# DO NOT DISTRIBUTE OR I WILL FIND YOU
if [ ! -n "$1" ]
    then
    echo "Usage: " $0 " job_to_kill"
    echo "      job_to_kill is MANDATORY"
    
    #List unique processes running uner my id
    UNIQUE_PROCESSES=`qstat | grep ${USER} | awk '{print $2}' | uniq`
    echo "job_to_kill must be one of: " $UNIQUE_PROCESSES
    exit
fi

echo "Trying to kill JOB: " $1
MYIDS=`qstat | grep ${USER} | grep $1 | awk -F. '{print $1}'`
echo "killing these ids: " $MYIDS
qdel $MYIDS

