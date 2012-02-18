#!/bin/bash

script=$(cd $(dirname $0) && pwd)
vault=$(cd $script/../../vault && pwd)
shared=$(cd $vault/../shared && pwd)

for dir in `ls $vault`
do
  target=$vault/$dir
  if [ ! -d $target ] ; then continue ; fi

  texDiff=`diff $target/question.tex $shared/question.tex | wc -l`
  plotDiff=`diff $target/figure.gnuplot $shared/figure.gnuplot | wc -l`

  if [ $texDiff -eq 0 ] ; then
    if [ $plotDiff -eq 0 ] ; then 
      echo "[*] $dir"
    else echo "[T] $dir"
    fi 
  elif [ $plotDiff -eq 0 ] ; then
    echo "[P] $dir"
  fi

done

