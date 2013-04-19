#!/bin/sh

# A shell script to start the main screen session on ANIM machines
# This can in theory run also on WARP (but please please only use PBS not this!)
# hacked up by Tomasz Malisiewicz (tomasz@cmu.edu)
# Run like: ./sc.sh script_name 8 10
# The above command will run "script_name" on machine 8 through machine 10
# $Id: sc.sh,v 1.20 2009/03/03 05:33:07 tmalisie Exp $
# $Date: 2009/03/03 05:33:07 $
# $Author: tmalisie $
# $Revision: 1.20 $

#This script starts the big job on N anim machines

#read command line argument 1 which is ALWAYS required
if [ ! -n "$1" ]
    then
    echo "Usage: " $0 " script_to_run [start_machine_id] [end_machine_id]"
    echo "      script_to_run is MANDTORY"
    exit
else
    PROC=$1
    echo "Found script: " $PROC
fi

#create a name for our driver screen session
export CLUSTY_SESSION_NAME=anim_manage

#determine if the driver session is already running
export ALREADY_RUNNING=`screen -list | grep anim_manage | wc -l`

if [ $ALREADY_RUNNING = "1" ]; then
    echo "Cannot Continue: SCREEN called $CLUSTY_SESSION_NAME is running."
    echo "Just run \"screen -rd\" to resume it"
    #we could be sneaky here and manage a running session, but we don't
    exit;
fi

echo 'Clearing Out Log Files'
rm /afs/cs.cmu.edu/user/${USER}/www/screenlogs/mylog*

## START THE DRIVER SCREEN SESSION ###
screen -L -c animrc  

#set the default start machine and end machine
export START_MACHINE=10
export END_MACHINE=15

#read optional command line argument 2
if [ -n "$2" ]
    then
    export START_MACHINE=$2
    echo "Setting START_MACHINE=" $2
fi

#read optional command line argument 2
if [ -n "$3" ]
    then
    export END_MACHINE=$3
    echo "Setting END_MACHINE=" $3
fi

#Here we must use a temporary HOME environment since we are skipping
#kerb and don't have local directory write access which compiled
#matlab scripts require
#STARTDIR=/nfs/hn01/tmalisie/compiled_labelme/
#export PROCESS_STRING="(setenv HOME /nfs/hn01/tmalisie/temphome/; cd ${STARTDIR}; nice +10 ./${PROC})"

#here we run uncompiled matlabs
STARTDIR=/nfs/hn22/tmalisie/ddip/
export PROCESS_STRING="(setenv HOME /nfs/hn01/tmalisie/temphome/; cd ${STARTDIR}; nice matlab -nodesktop -nosplash -r \"addpath(genpath(pwd));try,${PROC};,catch,disp('Error with script ${PROC}');end;exit(1);\")"

#STARTID is a temporary counter variable
STARTID='1'

#create a machine list which is simply START:END
MACHINELIST=`echo \`seq $START_MACHINE $END_MACHINE\``

for ind in $MACHINELIST
do
  export SSH_STRING="ssh anim${ind}.graphics.cs.cmu.edu"

  #echo Initializing Virtual Terminal $ind
  # a short sleep is critical to let screen re-adjust its socks
  sleep .4

  screen -S anim_manage -X screen -fn -t A:${ind} $STARTID $SSH_STRING $PROCESS_STRING
  
  #Be verbose -- it is good for the soul
  echo screen -S anim_manage -X screen -fn -t A:${ind} $STARTID $SSH_STRING $PROCESS_STRING
  
  STARTID=`expr $STARTID + 1`
done

echo 'Ending Screener scripty: Now run screen -rd'
