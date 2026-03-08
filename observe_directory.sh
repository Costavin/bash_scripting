#!/bin/bash

#This script uses polling as as to check if files are modified in a directory

get_list() {
	local list=("$(ls -lR | grep -Ev "total" | grep -Ev "^\\." | sort -u)")
	echo "${list}"
}

while getopts ':d:t:v' flag;	do
	case "${flag}" in
		d) tgt_dir=${OPTARG} ;;
		t) add_time=${OPTARG} ;;
		v) verbose=1 ;;
		*) echo "Invalid option: -${OPTARG}" && exit 1 ;;
	esac
done

if [ ! -d "${tgt_dir}" ]; then
		echo -ne "Directory doesn't exist, try again with the absolute path\nScript usage: ./observe_directory.sh -d <target_directory> -t <time> -v\n"
		exit
	else
		echo "Target directory: '${tgt_dir}'"
fi

if [[ -n "${add_time}" ]]; then
	ENDTIME=${add_time}
else
	ENDTIME=20
fi

oIFS=$IFS
IFS=$'\n'
SECONDS=0
counter=0

added=""
new_added=""
removed=""
modified=""
check_list=""


cd "${tgt_dir}" && initial_list=$( get_list )
lines=$(echo "${initial_list}" | wc -l)
echo -e "Number of elements observed: ${lines}\n"
initial_list+=$'\n'

while (( "${SECONDS}" < "${ENDTIME}" )); do
	check_list=$( get_list )

	for element in ${check_list}; do
		if [[ ! "${initial_list}" =~ "${element}" ]]; then			#same identical item not found, check if added, removed, modified
			filename=${element##*\ }				
			if [[ "${initial_list}" =~ "${filename}" ]]; then		#match -> file modified
				if [[ ! "${modified}" =~ "${element}" ]]; then
				if [[ ${verbose} == "1" ]]; then
					echo -e "Modified\t\n${element}\nEnd modified\n"
				fi
					modified+=${element}$'\n'
				fi
			else								#no match -> file added
				if [[ ${verbose} == "1" ]]; then
					echo -e "Added\t\n${element}\nEnd addition\n"
				fi
				new_added+=${element}$'\n'
			fi
		fi
	done
											#check if items removed
	for old_element in ${initial_list}; do
		if [[ ! "${check_list}" =~ "${old_element}" ]]; then
			if [[ ! "${removed}" =~ "${old_element}" ]]; then
				if [[ ${verbose} == "1" ]]; then
					echo -e "Removed\t\n${old_element}\nEnd removed\n"
				fi
				removed+=${old_element}$'\n'
			fi
		fi
	done

	if [[ -n "${new_added}" ]]; then						#check if added has been modified
		initial_list+=${new_added}						#update the initial list with added files
		added+=${new_added}
		new_added=""
	fi
	((counter++))
	sleep 0.5									#might wanna choose some other value to make it more reactive
done


echo -e "**********\t\tAdded files\t\t*************"
echo -e "${added}\n"
echo -e "**********\t\tModified files\t\t*************"
echo -e "${modified}\n"
echo -e "**********\t\tRemoved files\t\t*************"
echo -e "${removed}\n"
echo -e "Elapsed time: ${SECONDS} seconds\nExecuted: ${counter} times\n"

IFS=$oIFS
