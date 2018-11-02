#! /bin/bash
source ./set_navi.sh 2> /dev/null
set_array () {
  command_array=()
  grep_array=()
}

set_flag () {
  sp_flag=0
  cat_flag=0
  grep_flag=0
  grep_log_flag=0
  spcollect_flag=1
}

set_def () {
  context="other"
  ip=$spAip
  sp="spA"
  time=`date +%Y%m%d_%H-%M-%S`
  time_a=`date +%H%M%S`
  log_lines=300
  pid0=0
  pid1=0
  sleep_s=5
}

yesno () {
  # echo -n "Would you like to start? [Y/n]"
  read ANSWER
  case $ANSWER in     
    "" | "Y" | "y" | "yes" | "Yes" | "YES" )
        echo "* - start now..";;
    * ) echo "exit"
        exit;; 
  esac
}

set_sp () {
  if [ $1 = A ]; then
    sp="spA"
    ip=$spAip
  elif [ $1 = B ]; then
    sp="spB"
    ip=$spBip
  fi
  sp_flag=1
}

set_context () {
  if [ $1 = 0 ]; then
    context="before"
  elif [ $1 = 1 ]; then
    context="after"
  else 
    context="other"
  fi
}

flashleds () {
  echo  -n "flashleds:Bus#"$bus "enc#"$enc "[Y/n]"
  yesno
  naviseccli -h $ip -user $user -password $password -scope 0 flashleds -b $bus -e $enc on
  read -p "Please press enter to turn it off: "
  naviseccli -h $ip -user $user -password $password -scope 0 flashleds -b $bus -e $enc off
  exit
}

navi_output () {
  echo "* - execute : "$sp" : "$local_command
  naviseccli -h $ip -user $user -password $password -scope 0 $local_command >  "$context"-$sp"-$local_command""-$time_a".log
  chmod 444 "$context"-$sp"-$local_command""-$time_a".log
  if [ $cat_flag = 1 ];then 
    echo "* - cat : "$sp" : "$local_command
    cat "$context"-$sp"-$local_command""-$time_a".log
  fi
  if [ $grep_log_flag = 1 ];then 
    echo "* - log-grep : "$sp" : "$local_command
    cat "$context"-$sp"-$local_command""-$time_a".log | grep -e "(2500)" -e "(67d)" -e "(78c)" -e "(78d)" -e "(6aa)" -e "(2580)" -e "all reb" -e "event un"
  fi
}

navi_help () {
  echo "usage: navi [-all-bf] [-all-af] [-led] [-sp AorB] "
  echo "            [-r] [-log int] [-log-grep]"
  echo "            [-cat] [-sleep int] [-set]"
  echo "            [-all=v2-bf] [-all=v2-af]"
  echo "            [-disk] [-crus] [-fail]"
  echo "            [-spcollect] [-spcollect-list]"
  echo "            [-spcollect-retrieve]"
}

set_VNXcommand () {
  command_array=("${command_array[@]}" ="getcrus" )
  command_array=("${command_array[@]}" ="getdisk -messner -state -hs -rb -capacity -tla -rg -serial" )
  command_array=("${command_array[@]}" ="getlun -state -default -owner -usage" )
  command_array=("${command_array[@]}" ="getcache" )
  command_array=("${command_array[@]}" ="getall" )
  command_array=("${command_array[@]}" ="getlog -"$log_lines )
  command_array=("${command_array[@]}" ="faults -list" )
  command_array=("${command_array[@]}" ="storagepool -list" )
  command_array=("${command_array[@]}" ="getrg -messner" )
}

option_parsing () {
  while :
  do
    case $1 in
      "-h"|"--help" )
        navi_help
        exit 1
      ;;
  
      "-s"|"--setsp"|"-sp" )
        shift 1
        set_sp $1
        shift 1
        continue
      ;;

      "-A" )
        shift 1
        set_sp A
        shift 1
        continue
      ;;


      "-B" )
        shift 1
        set_sp B
        shift 1
        continue
      ;;

  
      "-c"|"--context" )
        shift 1
        set_context $1
        shift 1
        continue
      ;;
  
      "-b" )
        shift 1
        bus=$1
        shift 1
        continue
      ;;
  
      "-e" )
        shift 1
        enc=$1
        shift 1
        continue
      ;;
  
      "-sleep" )
        shift 1
        sleep_s=$1
        shift 1
        continue
      ;;
  
      "-a" | "--getagent" )
        cat_flag=1
        sp_flag=1
        command_array=("${command_array[@]}" ="getagent" )
        shift 1
        continue
      ;;
  
      "-crus"|"--getcrus" )
        command_array=("${command_array[@]}" ="getcrus" )
        shift 1
        continue
      ;;
  
      "--getall" )
        command_array=("${command_array[@]}" ="getall" )
        shift 1
        continue
      ;;
  
      "-disk"|"--getdisk" )
        command_array=("${command_array[@]}" ="getdisk -messner -state -hs -rb -capacity -tla -rg -serial" )
        shift 1
        continue
      ;;

      "-fail"|"--faults" )
        command_array=("${command_array[@]}" ="faults -list" )
        shift 1
        continue
      ;;

      "-led"|"--flashleds" )
        sp_flag=1
        flashleds 
        shift 1
        continue
      ;;
  
      "-getlog"|"-log"|"--getlog" )
        shift 1
        log_lines=$1
        command_array=("${command_array[@]}" ="getlog -"$log_lines )
        shift 1
        continue
      ;;

      "-log-grep" )
        shift 1
        log_lines=$1
        command_array=("${command_array[@]}" ="getlog -"$log_lines )
        grep_log_flag=1
        shift 1
        continue
      ;;

      "-all"|"-all=v1" )
        set_VNXcommand 
        shift 1
        continue
      ;;

      "-all-bf"|"-all=v1-bf" )
        log_lines=10000
        set_context 0
        set_VNXcommand 
        shift 1
        continue
      ;;

      "-all-af"|"-all=v1-af" )
        set_context 1
        set_VNXcommand 
        shift 1
        continue
      ;;

      "-all=v2" )
        set_VNXcommand 
        command_array=("${command_array[@]}" ="hotsparepolicy -list" )
        shift 1
        continue
      ;;

      "-all=v2-bf" )
        log_lines=10000
        set_VNXcommand 
        set_context 0
        command_array=("${command_array[@]}" ="hotsparepolicy -list" )
        shift 1
        continue
      ;;

      "-all=v2-af" )
        set_VNXcommand 
        set_context 1
        command_array=("${command_array[@]}" ="hotsparepolicy -list" )
        shift 1
        continue
      ;;

      "-spcollect" )
        echo -n  "Do you want to execute \"spcollect -messner\" ? [Y/n]"
        yesno
        naviseccli -h $ip -user $user -password $password -scope 0 spcollect -messner
        exit
      ;;

      "-spcollect-list" )
        echo -n  "Do you want to execute \"managefiles -list\" ? [Y/n]"
        yesno
        naviseccli -h $ip -user $user -password $password -scope 0 managefiles -list
        exit
      ;;

      "-spcollect-retrieve" )
        echo -n  "Do you want to execute \"managefiles -retrieve\" ? [Y/n]"
        yesno
        naviseccli -h $ip -user $user -password $password -scope 0 managefiles -retrieve 
        exit
      ;;

      "-cat" )
        cat_flag=1
        shift 1
        continue
      ;;

      "-set" )
        echo -n "Do you want to create set_navi.sh? [Y/n]"
        yesno
        init_setnavi
      ;;

      "-r" |"-read" )
        echo -n "input naviseccli_commands : "
        read read_command
        command_array=("${command_array[@]}" ="$read_command" )
        shift 1
        continue
      ;;
  
      * ) 
        if [ $# = 0 ]; then
          break
        fi
        shift 1
      ;;
  
    esac
  done
}




command_echo () {
  echo "* - "$sp":"$ip" - -"
  for ((i = 0; i < ${#command_array[@]}; i++)) {
    local_command=${command_array[i]}
    local_command=${local_command:1}
    echo $i":"$local_command
  }
}

command_execute () {
  for ((i = 0; i < ${#command_array[@]}; i++)) {
    local_command=${command_array[i]}
    local_command=${local_command:1}
    navi_output $local_command 
  }
}

chsp () {
  if [ $sp = spA ]; then
    ip=$spBip
    sp="spB"
  elif [ $sp = spB ]; then
    ip=$spAip
    sp="spA"
  fi
}

init_setnavi () {
  touch set_navi.sh
  chmod 777 set_navi.sh
  echo "#! /bin/bash" >> set_navi.sh
  echo "shopt -s expand_aliases" >> set_navi.sh
  echo "alias naviseccli=\"NaviSECCli.exe\"" >> set_navi.sh
  echo "user=\"sysadmin\"" >> set_navi.sh
  echo "password=\"sysadmin\"" >> set_navi.sh
  echo "bus=\"0\"" >> set_navi.sh
  echo "enc=\"0\"" >> set_navi.sh
  echo "slot=\"0\"" >> set_navi.sh
  echo "spAip=\"128.221.1.250\"" >> set_navi.sh
  echo "spBip=\"128.221.1.251\"" >> set_navi.sh
  echo "Set default to set_navi.sh"
  exit
}

if [ $# = 0 ]; then
  navi_help
  exit 1
fi
set_def
set_flag
set_array
option_parsing $@
echo "user / password : "$user " / " $password
echo "set_context : "$context
command_echo 
if [ $sp_flag = 0 ]; then
  chsp
  command_echo
  chsp
fi

echo -n "Would you like to start? [Y/n]"
yesno

command_execute &
pid0=$!
if [ $sp_flag = 0 ]; then
  sleep $sleep_s
  chsp
  command_execute &
  pid1=$!
fi

wait $pid0 2> /dev/null
wait $pid1 2> /dev/null