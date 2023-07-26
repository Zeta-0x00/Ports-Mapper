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




handler(){
  printf "\n\n${red}[X]${end} SIGINT detected\n\texiting...\n"
  rm "./cache.txt" 2>/dev/null
  exit 0
}

trap handler SIGINT

fhelp(){
  printf "${yellow}[!]${end} Usage:\n\t${green}./mapper.sh ${cyan}<ip>${end}\n\n"
  printf "${yellow}[!]${end} Dependencies:\n\t${purple}nc\n\tping${end}\n"
}

command_validation(){
  command -v "$1" > /dev/null
  if [ ! $? -eq 0 ]; then
    printf "${red}[X]${end} $1 not exist\n\n"
    fhelp
    exit 1
  fi
}

if [ $# -ne 1 ]; then
  fhelp
  exit 1
fi
host="$1"

printf "Host Address = ${cyan}$host${end}\n\n"

command_validation "nc"
command_validation "ping"

service_identifier(){
  local lport="$1"
  local cache=$(nc -zv -w 1 $host $lport 2>&1)
  local service=$(echo "$cache" | awk '{print $3}')
  local status=$(echo "$cache" | awk '{print $4}')
  printf "${yellow}[!]${end} Puerto ${cyan}$lport${end} -> ${purple}$service${end} is ${green}$status${end}\n"
}


Max=200
Current=0

#Identify machine OS by TTL
output=$(ping -c 1 $1 2>/dev/null)

ttl_line=$(echo "$output" | grep -o "ttl=[0-9]*")

ttl=$(echo "$ttl_line" | grep -o "[0-9]*")
if [[ $ttl -eq '' || $ttl -gt 128 ]]; then
  printf "${yellow}[!]${end} Unrecognised OS, TTL = ${cyan}$ttl${end}.\n\n"
elif [[ $ttl -le 128 && $ttl -gt 64 ]]; then
  printf "${green}[✓]${end} Possible Windows, TTL = ${cyan}$ttl${end}.\n\n"
elif [[ $ttl -le 64 ]]; then
  printf "${green}[✓]${end} Possible Unix/Linux, TTL = ${cyan}$ttl${end}.\n\n"
fi

#ports mapper
for i in  $(seq 1 65535); do
  while [[ $Current -ge $Max ]]; do
    sleep 0.1
    Current=$(jobs -p | wc -l)
  done

  {
    if  timeout 1 bash -c "echo '' > /dev/tcp/$host/$i" 2>/dev/null; then
      echo "$i" >> cache.txt
      printf "Port ${blue}$i${end} -> ${green}Open${end}\n"
    fi
  }  &
  Current=$(jobs -p | wc -l)
done

wait

open_ports=$(/bin/cat ./cache.txt | tr "\n" ",")
rm "./cache.txt"
open_ports=${open_ports%,}

printf "\nOpen Ports = ${blue} $open_ports ${end}\n\n"

for port in $(echo "$open_ports" | tr ',' ' '); do
  service_identifier "$port"
done
