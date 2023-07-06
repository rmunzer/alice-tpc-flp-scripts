## ALICE TPC FLP SCRIPTS

Collection of simple FLP scripts usefull for TPC operation


Usage:<br>
flp_execute.sh <required arguments> [optional arguments]  <br>
Action selection<br>
  -i, --init          		:  Initial Script
  
  -l, --links         		:  Link Status
  
  -a, --alf           		:  Restart ALF
  
      --alf_force     		:  Restart ALF (force resart)
  
  -o, --oos_dump    		:  Dump performance of IDC output proxy
  
  -s, --start_flp=    		:  Start FLP
  
  -f, --stop_flp=     		:  Stop FLP
  
  -p, --pp 	      		:  COnfig pattern player
  
      --pp_read 	      	:  COnfig pattern player
      
      --pp_new	 	      	:  COnfig pattern player (new Pattern Player)
      
      --pp_tf=        		:  Skipped TF in pp for re-sync (=0x1)
      
      --pp_bc=        		:  BC for re-sync (=0x8)
  
  -c, --cru_config    		:  Config CRU
  
      --cru_config_force    	:  Config CRU force
      
      --fw_copy=<file>          :  Copy firmware in to rescanning folder
      
      --fw_revert               :  Revert firmw in rescanning folder to golden version
  
  -r, --rescan        		:  Rescan (Reload Firmware)
  
      --rescan_full      	:  Rescan (Reload Firmware) - Using local file if available
  
  -h, --help          		:  Show Help

Requirements:
   
    Node with configured Private/Public key connection to FLP (e.g. lxplus, alice-tpc-test)
   
    Create folder
    
    Run: "git clone git@github.com:rmunzer/alice-tpc-flp-scripts.git <Path-to-your-folder>"
    
