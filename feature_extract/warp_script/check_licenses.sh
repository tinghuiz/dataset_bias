#!/bin/sh

#we have to do this on a 32 bit machine
cd /usr/local/lib/matlab7/etc/glnx86 2> /dev/null

#do this on our local 64 bit box
if [ -z `hostname | grep "_64"` ]; then
  cd /usr/local/lib/matlab7/etc/glnxa64 2>/dev/null
fi

./lmutil lmstat -a -c ../license.dat | grep -A 100 "Users of Image_Toolbox" | grep -B 100 -C 0 "Users of Neural_Network"
