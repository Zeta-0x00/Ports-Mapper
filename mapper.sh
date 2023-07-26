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
  exit 0
}

trap handler SIGINT


Max=200
Current=0

#Identify machine OS by TTL
output=$(ping -c 1 $1 2>/dev/null)

ttl_line=$(echo "$output" | grep -o "ttl=[0-9]*")

ttl=$(echo "$ttl_line" | grep -o "[0-9]*")
if [[ $ttl -eq '' || $ttl -gt 128 ]]; then
  printf "${yellow}[!]${end} OS no reconocido, valor TTL = ${cyan}$ttl${end}.\n"
elif [[ $ttl -le 128 && $ttl -gt 64 ]]; then
  printf "${green}[✓]${end} Posible Windows, TTL = ${cyan}$ttl${end}.\n"
elif [[ $ttl -le 64 ]]; then
  printf "${green}[✓]${end} Posible Unix/Linux, TTL = ${cyan}$ttl${end}.\n"
fi

#ports mapper
for i in  $(seq 1 65535); do
  while [[ $Current -ge $Max ]]; do
    sleep 0.1
    Current=$(jobs -p | wc -l)
  done

  {
    if  timeout 1 bash -c "echo '' > /dev/tcp/$1/$i" 2>/dev/null; then
      printf "Puerto ${blue}$i${end} -> ${green}abierto${end}\n"
    fi
  }  &
  Current=$(jobs -p | wc -l)
done

wait

