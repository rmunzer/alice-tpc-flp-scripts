pwd=$PWD
echo $pwd
export PATH=$PWD:$PWD/data_scripts:$PWD/data_scripts/pedestal:$PATH
opt1=`grep Action flp_execute.sh -A 30 | grep - | cut -f1 -d: | cut -f1 -d, | cut -f1 -d=`
opt2=`grep Action flp_execute.sh -A 30 | grep - | cut -f1 -d: | cut -f2 -d, | cut -f1 -d=`
echo $opt1 $opt2
_flp_execute(){
    local cur prev words cword split
    _init_completion -s || return
    $split && return

#    echo cur:$cur
#    echo prev:$prev
#    echo words:$words
#    echo cword:$cword
#    echo split:$split
#    echo 
    if [ "$prev" == "--fw_copy" ]; then
        comptopt -o filenames 2>/dev/null
        COMPREPLY=( $(compgen -f -- ${cur}) )
    elif [[ "$prev" == "-s" ]] || [[ "$prev" == "--start_flp" ]] || [[ "$prev" == "-f" ]]  || [[ "$prev" == "--stop_flp"  ]]; then
      num=`seq 1 145`
      COMPREPLY=( $(compgen -W "$num" -- "$2") )	    
    else
      COMPREPLY=( $(compgen -W "$opt1 $opt2" -- "$2") )
    fi
}
complete -F _flp_execute flp_execute.sh
