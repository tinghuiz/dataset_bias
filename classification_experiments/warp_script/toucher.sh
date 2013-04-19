#!/bin/sh

# A shell script to take my screenlogs and generate a simple
# visualization for viewing from another machine or my iPhone
# hacked up by Tomasz Malisiewicz (tomasz@cmu.edu)
# $Id: toucher.sh,v 1.5 2009/02/12 08:03:45 tmalisie Exp $
# $Date: 2009/02/12 08:03:45 $
# $Author: tmalisie $
# $Revision: 1.5 $

#Show this many last lines from each tab
SHOWLAST=20

#Wait this many seconds before re-generating output
REFRESH_TIME=20

#Output html page
RESFILE=/afs/cs.cmu.edu/user/tmalisie/www/screenlogs/index.html

sleep 1

while [ 1 -gt 0 ]; do
    echo "updating log at `date`"
    
    files=`find /afs/cs.cmu.edu/user/tmalisie/www/screenlogs/ -name "mylog*"`
    touch /afs/cs.cmu.edu/user/tmalisie/www/screenlogs/*

    echo "<html><head><title>SEG log</title></head><body>" > $RESFILE
    echo "<table border=2 align=top>" >> $RESFILE

    echo "<tr>" >> $RESFILE
    for f in $files
    do
      echo "<td valign=top><b>" >> $RESFILE
      echo $f >> $RESFILE
      echo "</b></td>" >> $RESFILE
    done    
    echo "</tr>" >> $RESFILE

    echo "<tr>" >> $RESFILE
    for f in $files
    do
      echo "<td valign=top><pre>" >> $RESFILE
      cat $f | tail -${SHOWLAST} >> $RESFILE
      echo "</pre></td>" >> $RESFILE
    done
    echo "</tr>" >> $RESFILE
    
    echo "</table>" >> $RESFILE
    echo "</body></html>" >> $RESFILE

    sleep ${REFRESH_TIME}
done
