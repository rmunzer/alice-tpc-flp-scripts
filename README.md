## ALICE TPC FLP SCRIPTS

Collection of simple FLP scripts usefull for TPC operation


Usage:

flp_execute <option> <start_flp> <stop_flp>

option:
    init             : copy scripts to flps
    links            : List fec counter on the CRU
    cru_config       : Configure FLP/CRU based on the configuratrion on consul
    cru_config_force : Configure FLP/CRU based on the configuratrion on consul
    restart_alf      : Restart Alf
    rescan           : Rescan CRUs (to be used if CRU does not sent data)
    pat              : Manual configuration of pattern Player 


