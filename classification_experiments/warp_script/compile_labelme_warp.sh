#!/bin/sh

# A shell script to compile my "Labelme" Project
# hacked up by Tomasz Malisiewicz (tomasz@cmu.edu)
# $Id: compile_labelme_warp.sh,v 1.1 2009/02/28 08:59:11 tmalisie Exp $
# $Date: 2009/02/28 08:59:11 $
# $Author: tmalisie $
# $Revision: 1.1 $

#read command line argument 1 which is ALWAYS required
if [ ! -n "$1" ]
    then
    echo "Usage: " $0 " script_to_run"
    exit
else
    PROC=$1
    echo "Compiling script: " $PROC
fi

#set the compilation and source directories
COMPILEDIR=/nfs/hn01/tmalisie/compiled_labelme_warp/
SOURCEDIR=/nfs/hn22/tmalisie/ddip

echo 'rebuilding (clear/remake) compile DIRECTORY: ' $COMPILEDIR
rm -rf ${COMPILEDIR}
mkdir ${COMPILEDIR} 

#for some reason, compiling matlab stuff sometimes doesn't work if
#files are scattered in many different directories, so we simply move
#everything into one directory
echo 'moving stuff into one directory'
cp ${SOURCEDIR}/util/LabelMeToolbox/* ${COMPILEDIR}
cp ${SOURCEDIR}/util/LabelMeUtil/* ${COMPILEDIR}
cp ${SOURCEDIR}/util/* ${COMPILEDIR}
cp ${SOURCEDIR}/baselearn/* ${COMPILEDIR}
cp ${SOURCEDIR}/context/* ${COMPILEDIR}
cp ${SOURCEDIR}/learn/* ${COMPILEDIR}
cp ${SOURCEDIR}/display/* ${COMPILEDIR}
cp ${SOURCEDIR}/segment/* ${COMPILEDIR}
cp ${SOURCEDIR}/recognize/* ${COMPILEDIR}
cp ${SOURCEDIR}/imfeats/* ${COMPILEDIR}
cp ${SOURCEDIR}/imfeats/feats14/* ${COMPILEDIR}
cp ${SOURCEDIR}/util/BSE-1.1/matlab/* ${COMPILEDIR}
cp ${SOURCEDIR}/util/ncut_multiscale_1_5/* ${COMPILEDIR}

cd ${COMPILEDIR}
echo "Starting Matlab compilation of " $PROC
matlab -nodesktop -nosplash -r "mcc -m ${PROC}; exit"
