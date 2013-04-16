#!/bin/sh
# A script to start my WARP job -- probably something from the DDIP pipeline
# hacked up by Tomasz Malisiewicz (tomasz@cmu.edu)
# Run like: ./warp_starter.sh script_name 10 2
# Above command will run matlab sript script_name repeated 
# 10 times taking up 2 cores per instance

#Logs are written to /lustre/${USER}/outputs/

# $Id: warp_starter.sh,v 1.4 2009/04/06 23:06:19 tmalisie Exp $
# $Date: 2009/04/06 23:06:19 $
# $Author: tmalisie $
# $Revision: 1.4 $

# DO NOT DISTRIBUTE OR I WILL FIND YOU

if [ ! -n "$1" ]
    then
    echo "Usage: " $0 " script_to_run REPEAT=1 PPN=2"
    echo "      script_to_run is MANDTORY"
    exit
else
    PROCSTRING=$1
    echo "Running: " $PROCSTRING
fi

#the REPEAT is the number of times we will run this script
if [ ! -n "$2" ]
    then
    REPEAT=1
    echo "Defaulting REPEAT to ${REPEAT}"
else
    REPEAT=$2
fi

#set number of cores reserved per process (a PBS variable)
if [ ! -n "$3" ]
    then
    PPN=2
    echo "Defaulting PPN to ${PPN}"
else
    PPN=$3
fi

#use PBS to start the job REPEAT times
#-N gives the name so that qstat and showq will display this name
#nodes=1 means we are handling parallelization at the high level and run non-MPI jobs
#-e and -o are the stderr and stdout logs
#-eo means that they are joined
#-v passes a command line argument into warp_driver.sh (so the driver knows what to execute!)

LOGDIR=/lustre/${USER}/outputs/

if [ ! -d ${LOGDIR} ]; then
    echo "Directory ${LOGDIR} not present, creating it"
    mkdir $LOGDIR
fi

LOGSTRING="-e ${LOGDIR} -o ${LOGDIR} -j oe"

for i in `seq 1 ${REPEAT}`;
  do
  qsub -N ${PROCSTRING} -l nodes=1:ppn=${PPN} ${LOGSTRING} -v PROCSTRING=${PROCSTRING} warp_driver.sh
done
