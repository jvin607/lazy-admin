#!/usr/bin/env bash

sepline="===================="

for USER in `ls /home/`
do
  len=`echo $USER | awk '{print length($0)}'`   # get length of username
  echo $USER
  sep="${sepline:$1:$len}"                      # set separator
  echo $sep                                     # print separator
  cnt=`last $USER | grep ^$USER | wc -l`        # count logins
  echo logins: $cnt                             # show login count
  last $USER | grep ^$USER | head -5            # show most recent logins
  echo 
done
