o2env.sh
HOMEPWD=`pwd`
echo $HOMEPWD
threshold=$1
folder=s$threshold
folder_ph=s${threshold}_physics
mkdir $folder
mkdir $folder_ph
preparePedestalFiles.sh -i "cdb-prod" -s $threshold -o $folder
mv $folder/pedestal_values.physics.txt  $folder_ph/pedestal_values.txt
mv $folder/threshold_values.physics.txt  $folder_ph/threshold_values.txt
echo $HOMEPWD
cd $folder
#prepare_blc.sh &
cd $HOMEPWD
echo $HOMEPWD
cd $folder_ph
pwd
#prepare_blc.sh &
cd $HOMEPWD



