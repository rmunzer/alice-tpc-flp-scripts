# ALICE TPC FLP TOOlS

## ALICE TPC FLP TOOLS 

Collection of simple FLP scripts usefull for TPC operation

Usage:
```
    flp_execute.sh [optional arguments]
    Action selection

    -i, --init         : Initial Script
    -l, --links        : Link Status
    -a, --alf          : Restart ALF
    --alf_force        : Restart ALF (force resart)
    -o, --oos_dump     : Dump performance of IDC output proxyv 
    -s, --start_flp=   :Start FLP
    -f, --stop_flp=    : Stop FLP
    -p, --pp           : COnfig pattern player
    --pp_read          : COnfig pattern player
    --pp_new           : COnfig pattern player (new Pattern Player)
    --pp_tf=           : Skipped TF in pp for re-sync (=0x1)
    --pp_bc=           : BC for re-sync (=0x8)v -c, --cru_config : Config CRU
    --cru_config_force : Config CRU force
    --fw_copy=         : Copy firmware in to rescanning folder
    --fw_revert        : Revert firmw in rescanning folder to golden version
    -r, --rescan       : Rescan (Reload Firmware)
    --rescan_full      : Rescan (Reload Firmware) - Using local file if available
    -h, --help         : Show Help
```    
Requirements:
   
    Node with configured Private/Public key connection to FLP (e.g. lxplus, alice-tpc-test)

## ALICE TPC DATA TOOLS

Tools for data usage:

get_alien_raw.sh : Get data from alien 
```
    - Copy raw tf data from alien to /tmp
    - Usage get_alien_raw.sh <runnumer> <lhcperiod>
    
```
get_alien_raw_global.sh
```
    - Copy raw tf data of global run from alien to /tmp
    - Usage get_alien_raw_global.sh <runnumer> <lhcperiod>
    
```
rawTFtoDigits.sh
```
    - Conver raw f file to digi.root file 
    - Usage get_alien_raw.sh <raw-tf file/ raw-tf filelisfile>
```
Requirements:
   
    Alien GRID certificate available (https://alice-doc.github.io/alice-analysis-tutorial/start/cert.html)

