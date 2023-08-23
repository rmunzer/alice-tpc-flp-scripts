## ALICE TPC FLP SCRIPTS

Collection of simple FLP scripts usefull for TPC operation


Usage:<br>
flp_execute.sh <required arguments> [optional arguments]  <br>
Action selection<br>

  -i, --init          		:  Initial Script<br>
  -l, --links         		:  Link Status<br>
  -a, --alf           		:  Restart ALF<br>
      --alf_force     		:  Restart ALF (force resart)<br>
  -o, --oos_dump    		:  Dump performance of IDC output proxyv
  -s, --start_flp=    		:  Start FLP<br>
  -f, --stop_flp=     		:  Stop FLP<br>
  -p, --pp 	      		:  COnfig pattern player<br>
      --pp_read 	      	:  COnfig pattern player<br>
      --pp_new	 	      	:  COnfig pattern player (new Pattern Player)<br>
      --pp_tf=        		:  Skipped TF in pp for re-sync (=0x1)<br>
      --pp_bc=        		:  BC for re-sync (=0x8)v
  -c, --cru_config    		:  Config CRU<br>
      --cru_config_force    	:  Config CRU force<br>
      --fw_copy=<file>          :  Copy firmware in to rescanning folder<br>
      --fw_revert               :  Revert firmw in rescanning folder to golden version<br>
  -r, --rescan        		:  Rescan (Reload Firmware)<br>
      --rescan_full      	:  Rescan (Reload Firmware) - Using local file if available<br>
  -h, --help          		:  Show Help<br>

Requirements:
   
    Node with configured Private/Public key connection to FLP (e.g. lxplus, alice-tpc-test)
   
    Create folder
    
    Run: "git clone git@github.com:rmunzer/alice-tpc-flp-scripts.git <Path-to-your-folder>"
    
