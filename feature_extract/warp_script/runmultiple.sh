#!/bin/sh
for ((i = 0 ;  i <= 150;  i++  ))
do
  ./warp_starter.sh apply_parallel_script 1 2
done
