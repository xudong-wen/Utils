#!/bin/bash
# Desc: part & mkfs the disks which has not yet partitioned, and write into fstab
# How_to_use:   nohup ./pfdisks.sh &
# congxin.tian@renren-inc.com

export PATH="${PATH}:/usr/local/bin:/usr/local/sbin:"

lockfile='/var/run/pfdisks.pid'

list_unparted_disks(){
    #Summary: print un-partitioned disk name to stdout (sda sdb cciss/c0d1 ...)

	# find un-partitioned/un-mkfsed dev names
	for dev_sysfs_path in  /sys/block/*
    do
        is_removable=`cat ${dev_sysfs_path}/removable`
        if [ $is_removable -eq 0 ];then
            node_name=`basename $dev_sysfs_path`
            if echo "${node_name}" | egrep -q '^loop|^ram|^dm' ;then
                continue
            else
                blkdev_size=`cat ${dev_sysfs_path}/size`
				blkdev_subparts_num=`ls -ld /sys/block/${node_name}/${node_name}* 2>/dev/null | wc -l`
                if [ ${blkdev_size} -gt 0  -a  ${blkdev_subparts_num} -eq 0 ];then
                    blkdev_name=`echo $node_name | sed 's,!,/,g'`  #e.g.: cciss!c0d0 -> cciss/c0d0
                    echo $blkdev_name
                fi
            fi
        fi
    done
}

# single instance
if test -f $lockfile;then
    oldpid=`cat $lockfile|head -1`
    if [ `ps -p $oldpid -o comm= | wc -l` -eq 1 ];then
        echo "Error: already running. [${oldpid}]"
        exit 1
    fi
else
    echo $$ > $lockfile
fi

trap "rm -fv $lockfile;exit 1;" 0 3 15

# check environment
which parted >/dev/null 2>&1 || exit 1

# to be partitioned disks sda sdb ... sorted alphabetically 
todo_disks=$( list_unparted_disks|sort -d | tr '\n' ' ')
[ "x${todo_disks}" = x ] && echo "No more disks to process, great!" && exit 0

# counting LABEL=*
last_label_num=$( awk '{if($3=="ext3"){label=$1;gsub("LABEL=","",label);print label} }' /etc/fstab | grep -i 'data' | grep -Po '\d+'| sort -n| tail -1 )
if [ x$last_label_num = x ];then
    next_label_num=1
else
    next_label_num=$( expr $last_label_num + 1 )
fi

#echo "Info: the next disk label is " "/data"$next_label_num

# partition & filesystem
for dsk in $todo_disks
do
    # Create partition
    printf "Info: partitioning $dsk ------"
    
    printf "  Partition table: "
    if parted -s "/dev/$dsk" -- mktable gpt ;then
        printf "Yes"
    else
        printf "No"
    fi
    
    printf "  Partition: "
    if parted -s "/dev/$dsk" -- mkpart primary 0 -1 ;then
            printf "Yes"
        else
            printf "No"
    fi
    printf "\n"
    
    sleep 5
    
    # Create filesystem [ext3] in background
    part_name=''
    label_name="/data${next_label_num}"
    if echo $dsk | grep -qi cciss ;then
        part_name="${dsk}p1"
    else
        part_name="${dsk}1"
    fi
    
    if test -b /dev/${part_name};then
        nohup mkfs.ext3 -m 2 -j -L ${label_name} /dev/${part_name} &
        (( next_label_num++ )) 
    else
        echo "Warn: /dev/${part_name} is not exist!" > /dev/stderr
        continue
    fi
    
    
    # Create item in /etc/fstab
    fstab_line="LABEL=${label_name}             ${label_name}                   ext3    defaults,noatime        1 2"
    if ! grep "$fstab_line" /etc/fstab;then
        echo "$fstab_line" >> /etc/fstab
        mkdir ${label_name}
    fi
    
done

wait
sleep 5

# tune2fs -c 0 -i 0 /dev/xxx
for dsk in $todo_disks
do
    part_name=''
    if echo $dsk | grep -qi cciss ;then
        part_name="${dsk}p1"
    else
        part_name="${dsk}1"
    fi
    
    if test -b /dev/${part_name};then
        tune2fs -c 0 -i 0 /dev/${part_name}
    else
        echo "Warn: /dev/${part_name} is not exist!" > /dev/stderr
    fi
done

# End
