#!/bin/bash


handler(){
  echo -e "\n\nSIGINT detected, exiting..."
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
  echo "OS no reconocido, valor TTL = $ttl."
elif [[ $ttl -le 128 && $ttl -gt 64 ]]; then
  echo "Posible Windows, TTL = $ttl ."
elif [[ $ttl -le 64 ]]; then
  echo "Posible Unix/Linux, TTL = $ttl."
fi


#ports mapper
for i in  $(seq 1 65535); do
  while [[ $Current -ge $Max ]]; do
    sleep 0.1
    Current=$(jobs -p | wc -l)
  done

  {
    timeout 1 bash -c "echo '' > /dev/tcp/$1/$i" && echo "Puerto $i abierto"
  } 2>/dev/null &
  Current=$(jobs -p | wc -l)
done

wait
