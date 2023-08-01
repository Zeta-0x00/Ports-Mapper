#!/bin/bash


# Author: Daniel Hoffman (aka. Z)
# This tool is to help scan ports using unix base OS


# region Colours
end="\033[0m\e[0m"
red="\e[0;31m\033[1m"
green="\e[0;32m\033[1m"
yellow="\e[0;33m\033[1m"
blue="\e[0;34m\033[1m"
purple="\e[0;35m\033[1m"
cyan="\e[0;36m\033[1m"
# endregion


# region Functions
handler()
{
  #######################
  # Function: handler
  # Description: Handler for SIGINT
  #######################
  printf "\n\n${red}[X]${end} SIGINT detected\n\texiting...\n"
  rm "./cache.txt" 2>/dev/null
  tput cnorm # show cursor
  exit 1
}

trap handler SIGINT # Ctrl + C

help()
{
  #######################
  # Function: help
  # Description: Show help menu
  #######################
  printf "${green}[✓]${end} Usage: ./mapper.sh -i <host> -p <ports> [options]\n\n"
  printf "\t${yellow}-h\t${end}Show this help menu\n\n"
  printf "\t${yellow}-i\t${end}Host to scan\n\n"
  printf "\t${yellow}-p\t${end}Ports to scan\n\t\t${yellow}[!]${end} example: ${purple}-p 80,53,443,1433\n"
  printf "\t\t${yellow}-p-\t${end}Scan all ports\n\n"
  printf "\t${yellow}-o\t${end}Output to file\n\n"
  printf "\t${yellow}-x\t${end}Copy ports to clipboard\n\n"
  printf "\t${yellow}-n\t${end}No ping\n\n"
  printf "\t${yellow}-t\t${end}Max threads\n\n"
  printf "\t${yellow}-u\t${end}UDP scan\n\n"
  printf "\t${yellow}-s\t${end}Service identifier\n\n"
}

showDependencies()
{
  #######################
  # Function: showDependencies
  # Description: Show dependencies
  #######################
  printf "${green}[✓]${end} Dependencies:\n\n"
  printf "\t${yellow}nc${end}\n"
  printf "\t${yellow}ping${end}\n"
  printf "\t${yellow}uname${end}\n"
  printf "\t${yellow}xclip${end} On GNU/Linux machine\n"
  printf "\t${yellow}pbcopy${end} On macOS machine\n\n"
  printf "\t${yellow}shuf${end}\n\n"
}

command_validation()
{
  #######################
  # Function: command_validation
  # Description: Validate if command exist
  #######################
  command -v "$1" > /dev/null
  if [ ! $? -eq 0 ]; then
    printf "${red}[X]${end} $1 not exist\n\n"
    showDependencies
    exit 1
  fi
}

ServiceIdentifier()
{
  #######################
  # Function: service_identifier
  # Description: Identify service by port with nc
  #######################
  local lport="$1"
  local output="$2"
  local udp="$3"
  if [[ $udp == "true" ]]; then
    local cache=$(nc -v -n -u -z -w 1 $host $lport 2>&1)
  else
    local cache=$(nc -v -n -z -w 1 $host $lport 2>&1)
  fi
  local service=$(echo "$cache" | awk '{print $3}')
  local status=$(echo "$cache" | awk '{print $4}')
  printf "${yellow}[!]${end} Puerto ${cyan}$lport${end} -> ${purple}$service${end} ${green}$status${end}\n"
  if [[ $output != "" ]]; then
    echo "$lport $service $status" >> "$output"
  fi
}

Identify_OS()
{
  #######################
  # Function: Identify_OS
  # Description: Identify OS by TTL
  #######################
  local ttl=$1
  if [[ $ttl -eq '' || $ttl -gt 128 ]]; then
    printf "${yellow}[!]${end} Unrecognised OS, TTL = ${cyan}$ttl${end}.\n\n"
  elif [[ $ttl -le 128 && $ttl -gt 64 ]]; then
    printf "${green}[✓]${end} Possible Windows, TTL = ${cyan}$ttl${end}.\n\n"
  elif [[ $ttl -le 64 ]]; then
    printf "${green}[✓]${end} Possible Unix/Linux, TTL = ${cyan}$ttl${end}.\n\n"
  fi
}

Get_TTL()
{
  #######################
  # Function: Get_TTL
  # Description: Get TTL from ping
  #######################
  local output=$(timeout 1 ping -c 1 $1 2>/dev/null)
  local ttl=$(echo "$output" | grep -o "ttl=[0-9]*" | grep -o "[0-9]*")
  Identify_OS "$ttl"
}

setClipboardOS()
{
  #######################
  # Function: setClipboardOS
  # Description: Identify if host is mac or linux to set clipboard command
  #######################
  local output=$(uname)
  if [[ $output == "Darwin" ]]; then
    printf "${green}[✓]${end} Host is Mac\n\n"
    clipboard="pbcopy"
    command_validation "pbcopy"
  elif [[ $output == "Linux" ]]; then
    printf "${green}[✓]${end} Host is Linux\n\n"
    clipboard="xclip -sel clip"
    command_validation "xclip"
  fi
}

testToWrite()
{
  #######################
  # Function: testToWrite
  # Description: Test to write to file
  #######################
  touch "FileTest.z" 2>/dev/null
  if [[ ! $? -eq 0 ]]; then
    printf "${red}[X]${end} Can't write to file\n\n"
    exit 1
  else
    printf "${green}[✓]${end} Test to write success\n\n"
    rm "FileTest.z" 2>/dev/null
  fi
}

CopyPorts()
{
  #######################
  # Function: CopyPorts
  # Description: Copy ports to clipboard
  #######################
  local ports="$1"
  printf "\n${yellow}[!]${end} Copying ports to clipboard...\n\n"
  echo -n "$ports"| tr " " "," | $clipboard
  printf "${green}[✓]${end} Ports copied to clipboard\n"
  printf "${green}[✓]${end} Done\n\n"
}
# endregion


# region Globals
Max=200
Current=0
clipboard=""

command_validation shuf
command_validation "uname"
# endregion


# region mapper
Mapper()
{
  #######################
  # Function: Mapper
  # Description:  mapper function
  # Arguments: host, ports, service identifier, copy, no ping, output, udp
  #######################
  local host="$1"
  local ports="$2"
  local service_identifier="$3"
  local copy="$4"
  local no_ping="$5"
  local output="$6"
  local udp="$7"
  local paux=""
  local cache="./cache.z"
  

  # if no ping is not set then get ttl
  if [[ $no_ping != "true" ]]; then
    command_validation "ping"
    Get_TTL "$host"
  else
    printf "${yellow}[!]${end} No ping\n\n"
  fi
  # if no copy
  if [[ $copy != "true" ]]; then
    printf "${yellow}[!]${end} No copy\n\n"
  else
    setClipboardOS
  fi
  # if no output
  if [[ $output == "" ]]; then
    printf "${yellow}[!]${end} No output\n\n"
  fi
  # if service identifier is set
  if [[ $service_identifier == "true" ]]; then
    printf "${green}[✓]${end} Service identifier\n\n"
    command_validation "nc"
  else
    printf "${yellow}[!]${end} No service identifier\n\n"
  fi

tput civis # hide cursor

  # if ports is seq or ports is array
  if [[ $ports == "seq"* ]]; then
    paux=$ports
  else
    paux="echo $ports"
  fi

  # if udp is set
  if [[ $udp == "true" ]]; then
    printf "${green}[✓]${end} UDP scan\n\n"
    command_validation "nc"
    # udp
    for lport in $($paux) ; do
      while [[ $Current -ge $Max ]]; do
        sleep 0.1
        Current=$(jobs -p | wc -l)
      done
      {
        if timeout 1 bash -c "nc -w 1 -u $host $lport" 2>/dev/null; then
        printf "${green}[✓]${end} Port ${cyan}$lport${end} (UDP)\n"
        echo "$lport" >> "$cache"
        fi
      } &
      Current=$(jobs -p | wc -l)
    done
    wait
  else
    printf "${green}[✓]${end} TCP scan\n\n"
    # tcp
    for lport in $($paux) ; do
      while [[ $Current -ge $Max ]]; do
        sleep 0.1
        Current=$(jobs -p | wc -l)
      done
      {
        if timeout 1 bash -c "echo '' > /dev/tcp/$host/$lport" 2>/dev/null; then
        printf "${green}[✓]${end} Port ${cyan}$lport${end}\n"
        echo "$lport" >> "$cache"
        fi
      } &
      Current=$(jobs -p | wc -l)
    done
    wait
  fi
  
  # if there is no ports open implies there is no cache file
  if [ ! -f "$cache" ]; then
    printf "\n${red}[X]${end} No ports open\n\n"
    tput cnorm # show cursor
    exit 1
  fi

  ports=$(cat "$cache" | sort -n | uniq | tr '\n' ' ' | sed 's/.$//') # read cache file and sort
  rm "$cache" 2>/dev/null # remove cache file
  
  if [[ $service_identifier != "true" && $output != "" ]]; then
    printf "\n${yellow}[!]${end} Exporting ports to file...\n\n"
    if [[ $udp == "true" ]]; then
      echo "$host -> UDP" >> "$output"
    else
      echo "$host -> TCP" >> "$output"
    fi
    echo "$ports" >> "$output"
    printf "${green}[✓]${end} Done\n\t${purple}[!]${end} Ports exported in ${cyan}$output${end}\n\n"
  fi

  # Process to identify service
  if [[ $service_identifier == "true" ]]; then
    printf "\n${yellow}[!]${end} Identifying service...\n\n"
    if [[ $output != "" ]]; then
      if [[ $udp == "true" ]]; then
        echo "$host -> UDP" >> "$output"
      else
        echo "$host -> TCP" >> "$output"
      fi
    fi
    for port in $(echo "$ports"); do
      ServiceIdentifier "$port" "$output" "$udp"
    done
    if [[ $output != "" ]]; then
      printf "\n${green}[✓]${end} Done\n\t${purple}[!]${end} Ports and services exported in ${cyan}$output${end}\n\n"
    else
      printf "\n${green}[✓]${end} Done\n\n"
    fi
    else
      printf "\n${green}[✓]${end} Done\n\n"
  fi

  if [[ $copy == "true" ]]; then
    CopyPorts "$ports"
  fi
  tput cnorm # show cursor
}


# endregion




#region main

main()
{
  #######################
  # Function: main
  # Description: Main function
  # Arguments: -h (help) -i (host) -p (ports) -p- (all ports) -o (output) -s (service identifier)
  #            -x (copy ports to clipboard) -n (no ping) -t (max threads) -u (udp)
  #######################
  
  #if no args
  if [[ $# -eq 0 ]]; then
    help
    exit 1
  fi

  local host=""
  local ports=""
  local output=""
  local copy=""
  local no_ping=""
  local max_threads=""
  local udp=""
  local service_identifier=""
  local all_ports=""

  while getopts "hi:p:o:xnt:us" opt; do
    case $opt in
      h)
        help
        exit 0
        ;;
      i)
        host="$OPTARG"
        ;;
      p)
        ports="$OPTARG"
        # -p-
        if [[ $ports == "-" ]]; then
          all_ports="true"
        fi
        ;;
      o)
        output="$OPTARG"
        ;;
      x)
        copy="true"
        ;;
      n)
        no_ping="true"
        ;;
      t)
        max_threads="$OPTARG"
        ;;
      u)
        udp="true"
        ;;
      s)
        service_identifier="true"
        ;;
      *)
        help
        exit 1
        ;;
    esac
  done

  # ports validation
  if [[ $ports == "" && $all_ports == "" ]]; then
    printf "${red}[X]${end} Ports not specified\n\n"
    help
    exit 1
  fi
  # ports range -p80,52,22,443 etc
  if [[ $ports =~ ^[0-9,-]+$ ]]; then
    ports=$(echo "$ports" | sed 's/,/ /g')
  else
    printf "${red}[X]${end} Invalid ports\n\n"
    help
    exit 1
  fi
  # all ports
  if [[ $all_ports == "true" ]]; then
    ports="seq 1 65535"
  fi
  # host validation
  if [[ $host == "" ]]; then
    printf "${red}[X]${end} Host not specified\n\n"
    help
    exit 1
  fi
  # max threads validation if not number if not empty
  if [[ $max_threads != "" && ! $max_threads =~ ^[0-9]+$ ]]; then
    printf "${red}[X]${end} Invalid max threads\n\n"
    help
    exit 1
  fi
  # max threads validation if number if not empty
  if [[ $max_threads != "" && $max_threads =~ ^[0-9]+$ ]]; then
    Max="$max_threads"
    printf "${green}[✓]${end} Max threads: ${cyan}$Max${end}\n\n"
  fi
  # max threads validation if empty
  if [[ $max_threads == "" ]]; then
    Max=200
    printf "${green}[✓]${end} Default Max threads: ${cyan}$Max${end}\n\n"
  fi

  # output validation
  if [[ $output != "" ]]; then
    printf "${green}[✓]${end} Output to file: ${cyan}$output${end}\n\n"
    # if file exist
    if [[ -f $output ]]; then
      printf "${red}[X]${end} File exist, overwrite? [y|n]?\n"
      read -r overwrite
      if [[ $overwrite == "y" ]]; then
        testToWrite
      else
        printf "${yellow}[!]${end} Creating new file...\n"
        #random number
        random=$(shuf -i 1-100000 -n 1)
        output=$(echo "output_${random}.z")
        printf "${green}[✓]${end} New file: ${cyan}$output${end}\n\n"
      fi
    fi
  fi
  Mapper "$host" "$ports" "$service_identifier" "$copy" "$no_ping" "$output" "$udp"
  
}

main "$@"