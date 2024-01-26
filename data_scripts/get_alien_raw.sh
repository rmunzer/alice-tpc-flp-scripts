run=$1
period=LHC23zzo_TPC
num_files=5
folder=/alice/data/2023/${period}/${run}
echo Folder 1: $folder
sub1=`alien.py ls ${folder}`
folder=/alice/data/2023/${period}/${run}/${sub1}
echo Folder 2: $folder

counter=0
alien.py ls ${folder} > /tmp/alien_raw_folder
cat /tmp/alien_raw_folder
while read -r line
do
	folder=/alice/data/2023/${period}/${run}/${sub1}/${line}
	echo Folder 2: $folder
	alien.py ls ${folder} >> /tmp/alien_raw_files
	while read -r line2
	do
		echo $line2	
		echo alien.py cp /alice/data/2023/${period}/${run}/${sub1}/${line}/${line2} file:/tmp/
		alien.py cp /alice/data/2023/${period}/${run}/${sub1}/${line}/${line2} file:/tmp/
		counter=$((counter+1));
		echo /tmp/${line} >> run_${run}
		if [[ $counter -ge $num_files ]]
		then
		break
		 fi
	done < /tmp/alien_raw_files	
done < /tmp/alien_raw_folder



counter=0
ls /tmp/*${1}* > run_${1}
rm /tmp/alien_raw_files
rm /tmp/alien_raw_folder
