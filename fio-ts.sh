#!/bin/bash
#set -x
# Author: Mik 
# Version : v1.0.0
# Description: SSD FIO performance test script


usage(){
cat << EOF
usage: $0 <device>
The '<device>'  must an block device (eg: /dev/nvme0n1 or /dev/sda).
EOF
}


if [[ ! -b $1 ]]; then
	usage
else
	filename=$1
fi


if [[ $USER == 'root' ]];then
	echo 'root'
else
	read -r -p "input the $USER password" passwd
fi


BS=(4k)
QD=(1)
TC=(1)
MIXR=(100 0)


function clean_results(){
	rm -rf results/*
}


function test() {
	for tc in "${TC[@]}";do
		for qd in "${QD[@]}";do
			for bs in "${BS[@]}";do
				for mixR in "${MIXR[@]}";do
					dir=results/TC${tc}QD${qd}_${bs}_mixR${mixR}
					mkdir -p "${dir}"
					if [[ $mixR == 100 ]];then
						#Random reads.
						fio --filename="${filename}"  --rw=randread --bs="${bs}" --direct=1 --ioengine=libaio \
						--iodepth="${qd}" --runtime=60 --ramp_time=30 --startdelay=30 --numjobs="${tc}" --name=random \
						--group_reporting --thread --log_avg_msec=1000 --write_bw_log="${dir}/random"  \
						--write_lat_log="${dir}/random" --write_iops_log="${dir}/random"  \
						--output="${dir}/random" 

						#Sequential reads.
						fio --filename="${filename}"  --rw=read --bs="${bs}" --direct=1 --ioengine=libaio \
						--iodepth="${qd}" --runtime=60 --ramp_time=30 --startdelay=30 --numjobs="${tc}" --name=seq \
						--group_reporting --thread --log_avg_msec=1000 --write_bw_log="${dir}"/seq  \
						--write_lat_log="${dir}"/seq --write_iops_log="${dir}"/seq  --output="${dir}"/seq

					elif [[ $mixR == 0 ]];then
						#Random writes.
						fio --filename="${filename}"  --rw=randwrite --bs="${bs}" --direct=1 --ioengine=libaio \
						--iodepth="${qd}" --runtime=60 --ramp_time=30 --startdelay=30 --numjobs="${tc}" --name=random \
						--group_reporting --thread --log_avg_msec=1000 --write_bw_log="${dir}/random"  \
						--write_lat_log="${dir}/random" --write_iops_log="${dir}/random"  \
						--output="${dir}/random"

						#Sequential writes.
						fio --filename="${filename}"  --rw=write --bs="${bs}" --direct=1 --ioengine=libaio \
						--iodepth="${qd}" --runtime=60 --ramp_time=30 --startdelay=30 --numjobs="${tc}" --name=seq \
						--group_reporting --thread --log_avg_msec=1000 --write_bw_log="${dir}"/seq  \
						--write_lat_log="${dir}"/seq --write_iops_log="${dir}"/seq  --output="${dir}"/seq

					elif (("$mixR" < 100)) && (("$mixR" > 0));then
						#Random mixed reads and writes.
						fio --filename="${filename}"  --rw=randrw --rwmixread="$mixR" --bs="${bs}" --direct=1 \
						--ioengine=libaio --iodepth="${qd}" --runtime=60 --ramp_time=30 --startdelay=30 --numjobs="${tc}" \
						--name=random --group_reporting --thread --log_avg_msec=1000 \
						--write_bw_log="${dir}"/random --write_lat_log="${dir}"/random \
						--write_iops_log="${dir}"/random  --output="${dir}"/random

						#Sequential mixed reads and writes.
						fio --filename="${filename}"  --rw=rw --rwmixread="$mixR" --bs="${bs}" --direct=1 \
						--ioengine=libaio --iodepth="${qd}" --runtime=60 --ramp_time=30 --startdelay=30 --numjobs="${tc}" \
						--name=seq --group_reporting --thread --log_avg_msec=1000 --write_bw_log="${dir}"/seq \
						--write_lat_log="${dir}"/seq --write_iops_log="${dir}"/seq  --output="${dir}"/seq
					
					else
						echo Mixed read and write parameters are incorrect
					fi

				done
			done
		done
	done
}

clean_results
test