## ALICE TPC FLP SCRIPTS

Collection of simple FLP scripts usefull for TPC operation


>Usage:<br>
>flp_execute.sh <required arguments> [optional arguments]  <br>
>Action selection<br>
>-i, --init          		:  Initial Script  <br>
>-l, --links         		:  Link Status<br>
>-a, --alf           		:  Restart ALF<br>
>  	  --alf_force     		:  Restart ALF (force resart)<br>
>-s, --start_flp=    		:  Start FLP<br>
>-f, --stop_flp=     		:  Stop FLP<br>
>-p, --pp 	      				:  COnfig pattern player<br>
>  --pp_tf=        		:  Skipped TF in pp for re-sync (=0x1)<br>
>        --pp_bc=        		:  BC for re-sync (=0x8)<br>
>-c, --cru_config    		:  Config CRU<br>
>    --cru_config_force    	:  Config CRU force<br>
>-r, --rescan        		:  Rescan (Reload Firmware)<br>
>-h, --help          		:  Show Help<br>

Requirements:
   
    Node with configured Private/Public key connection to FLP (e.g. lxplus, alice-tpc-test)
   
    Create folder
    
    Run: "git clone git@github.com:rmunzer/alice-tpc-flp-scripts.git <Path-to-your-folder>"
    
