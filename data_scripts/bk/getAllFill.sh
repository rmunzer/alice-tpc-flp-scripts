#! /bin/bash

FILLS=$1


echo "#############################################################"
echo "###################  $FILLS #################################"
echo "#############################################################"
echo
echo "###################  FILL Stats #############################"
echo
getFillStats.sh $FILLS
echo
echo "###################  Runs Statistics ########################"
echo
getRunStats.sh $FILLS
echo
echo "###################  Eor Statisstics ########################"
echo
getEoRStats.sh $FILLS
echo

