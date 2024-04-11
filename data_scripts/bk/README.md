# ALICE BK Tools

## Metascripts

1. getEoRStats.sh ${FILLNUMBER}  # Get EoR Reason for fill
2. getFillStats.sh ${FILLNUMER}  # Get Fill Efficiency 
3. getRunStats.sh ${FILLNUMBER}  # Get Run Statistics with ctp trigger information

4. getAllFill.sh ${FILLNUMER} # Get all information from 1.,.2,3. for a fill 

5. getListFills.sh # get 1.,2. from all Stable Beams fills


## getBKFills.sh 

Usage: getBKFills.sh [OPTION...]
   -d           Debug
   -F FillNo    Number of the fill
   -s selection fields selection (comma-separated)


## getBKLogs.sh

Usage: getBKLog.sh [OPTION...]
   -d           Debug
   -F FillNo    Number of the fill
   -s selection fields selection (comma-separated)


## getBKRuns.sh

Usage: getBKRuns.sh [OPTION...]
   -d           Debug
   -f Date      Starting date/time (default: 7 days ago)
   -t Date      Ending date/time (default: NOW)
   -F FillNo    Number of the fill(s) (comma-separated) (disables date/time-based selection)
   -D seconds   Minimum run duration (in seconds)
   -s selection fields selection (comma-separated)
   -c get ctp information
   -g   good runs only


