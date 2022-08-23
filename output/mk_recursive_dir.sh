#!/bin/bash

mk_recursive_dir(){
    dirr=$1
    OPENDAPHOST=$2
    IFS='/'
    read -a strarr <<< "$dirr"
    IFS=""
    rdir=""
    #lf="temp.com"
    lf=`mktemp`

    for val in "${strarr[@]}";
    do
        rdir=`printf "%s%s/" $rdir $val `
        echo  "mkdir $rdir" > $lf
        echo sftp -b $lf $OPENDAPHOST # > log  2>&1 
        sftp -b $lf $OPENDAPHOST  > log  2>&1 
        if [[ $? != 0 ]]; then
          echo "Dir $rdir already exists on $OPENDAPHOST."
        else
          echo "mkdir-d $rdir on $OPENDAPHOST."
        fi
        rm $lf
    done
}
