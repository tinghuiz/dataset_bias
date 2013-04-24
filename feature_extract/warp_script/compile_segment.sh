#!/bin/sh

# A shell script to compile my "Segment" Project
# hacked up by Tomasz Malisiewicz (tomasz@cmu.edu)
# $Id: compile_segment.sh,v 1.10 2006/08/03 19:12:47 tmalisie Exp $
# $Date: 2006/08/03 19:12:47 $
# $Author: tmalisie $
# $Revision: 1.10 $

#set the compilation and source directories
COMPILEDIR=~/home_anim/compiled_segment
SOURCEDIR=~/home_anim/segment

echo 'erasing compile DIRECTORY: ' $COMPILEDIR
rm -r ${COMPILEDIR} 

echo 'copying source DIRECTORY: ' $SOURCEDIR ' into compile directory'
cp -r ${SOURCEDIR} ${COMPILEDIR}

#for some reason, compiling matlab stuff sometimes doesn't work if files
#are scattered in many different directories, so we simply move everything
echo 'moving stuff into one directory'
mv ${COMPILEDIR}/mori/superpixels/*.m ${COMPILEDIR}/matlab
mv ${COMPILEDIR}/mori/superpixels/yu_imncut/* ${COMPILEDIR}/matlab
mv ${COMPILEDIR}/BSE-1.1/matlab/* ${COMPILEDIR}/matlab
mv ${COMPILEDIR}/matlab/lda2/* ${COMPILEDIR}/matlab
mv ${COMPILEDIR}/matlab/ctm/code/* ${COMPILEDIR}/matlab
mv ${COMPILEDIR}/matlab/lightspeed/* ${COMPILEDIR}/matlab
mv ${COMPILEDIR}/matlab/fastfit/* ${COMPILEDIR}/matlab
mv ${COMPILEDIR}/matlab/display/* ${COMPILEDIR}/matlab
mv ${COMPILEDIR}/matlab/scripts/* ${COMPILEDIR}/matlab
mv ${COMPILEDIR}/matlab/mseg_study/* ${COMPILEDIR}/matlab

echo 'copying pascal code into one directory'
cp ~/home_anim/pascal/* ${COMPILEDIR}/matlab
cp ~/home_anim/VOC2006/VOCcode/* ${COMPILEDIR}/matlab

#get the process name form the PROCFILE
#this is done because the current process is referenced in many files
#and we never want to edit that in multiple spots
PROC=`cat CURPROC`

echo 'compiling the Process' $PROC
cd ~/home_anim/compiled_segment/matlab/
matlab -r "mcc -m ${PROC}; exit"


