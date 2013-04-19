#!/bin/sh

# A script to start my WARP job -- probably something from the DDIP pipeline
# hacked up by Tomasz Malisiewicz (tomasz@cmu.edu)
# THIS IS A DRIVER THAT SHOULD ONLY BE CALLED FROM warp_starter.sh
# DO NOT CALL THIS SCRIPT DIRECTLY!!!

# DO NOT DISTRIBUTE OR I WILL FIND YOU
# $Id: warp_driver.sh,v 1.4 2009/04/06 23:06:18 tmalisie Exp $
# $Date: 2009/04/06 23:06:18 $
# $Author: tmalisie $
# $Revision: 1.4 $

if [ ! -n "$PROCSTRING" ]
    then
    echo "PROCSTRING UNDEFINED, not running anything"
    exit
fi

#Output gets written to a unique file per process
OUTPUT_FILER=/lustre/tinghuiz/temp_files/warp_output/${PROCSTRING}.${HOSTNAME}.$$.output

#1.) Jump into my home directory
#cd /lustre/abhinavg/physics_statics/code/code/newocclusion/code
#cd /lustre/abhinavg/physics_statics/code/code/derek_loop
#cd /lustre/abhinavg/physics_statics/code/code/code
#cd /nfs/hn26/abhinavg/onega/prob_code
#cd /nfs/ladoga_no_backups/users/tinghuiz/he-svm/imagenet
cd /nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments

#2.) run a niced matlab script 
#2a) add all subdirectories
#2b) execute the process PROCSTRING which is visible after adding paths 
#2c) exit matlab after running, or on error
#2d) keep writing output to some files continually
nice matlab -nodesktop -nosplash -r "addpath(genpath(pwd)); try,${PROCSTRING};,catch,disp('Error with script ${PROCSTRING}');end;exit(1);" > $OUTPUT_FILER

echo "Finished Without Problems" >> $OUTPUT_FILER
echo "..::Vision Solved::.."
