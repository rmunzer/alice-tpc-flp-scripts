
input="./threshold_values.txt"
while IFS= read  -r line
do 
   cru=`echo $line | cut -d' ' -f1`
   side=0
   if [ $cru -ge 180 ]
   then 
	 side=1
   fi
   if [ $side -ge 0 ]
   then
      fec=`echo $line | cut -d' ' -f2`
      threshold=`echo $line | cut -d' ' -f3`
      sector=$(expr $cru / 10)
      partition=$(expr $cru - $sector  \* 10 )
      par=$(expr $partition % 2)
      partition=$(expr $partition / 2)
      M_S=S
      if [ $par -eq 0 ]
      then
          M_S=M
      fi
      sector=$(expr $sector - $side \* 18 )

      if [ $sector -lt 10 ]
      then
	 sector="0"$sector
      fi

      echo $fec" "$threshold >> $M_S"_TPC-FEE_"$side"_"$sector"_"$partition"_threshold.cfg"
   fi
done <$input
