#!/bin/sh

# Process Terminator
# hacked up by Tomasz Malisiewicz (tomasz@cmu.edu)
# $Id: kill_all_matlabs.sh,v 1.9 2009/03/03 05:19:00 tmalisie Exp $
# $Date: 2009/03/03 05:19:00 $
# $Author: tmalisie $
# $Revision: 1.9 $

#SSH into all anim machines and kill all processes started by me that
#start with the prefix "script"

for i in `seq 1 15`;
do
  echo Killing script on anim $i
  ssh anim${i}.graphics.cs.cmu.edu pkill MATLAB
done

#kill the toucher script
pkill toucher