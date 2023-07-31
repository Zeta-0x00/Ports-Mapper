# Ports Mapper
Simple tool for port scanning and port service enumeration.

The reason for this tool is mainly to facilitate moments in security audits where it is known that map cannot be used for various reasons on the network.

# Dependencies
- nc
- ping
- pbcopy (MacOS) | xclip (Linux)
- shuf
# Usage
*Help menu:*
```bash
~$ chmod +x mapper.sh
~$ ./mapper.sh -h
[✓] Usage: ./mapper.sh -i <host> -p <ports> [options]

	-h	Show this help menu

	-i	Host to scan

	-p	Ports to scan
		[!] example: -p 80,53,443,1433
		-p-	Scan all ports

	-o	Output to file

	-x	Copy ports to clipboard

	-n	No ping

	-t	Max threads

	-u	UDP scan

	-s	Service identifier
```
*Exmple*
```haskell
~$ ./mapper.sh -i 10.10.43.2 -p- -s -n -x -t 5000
[✓] Max threads: 5000

[!] No ping

[✓] Host is Mac

[!] No output

[✓] Service identifier

[✓] TCP scan

[✓] Port 80
[✓] Port 53
[✓] Port 27998
[✓] Port 37443
[✓] Port 37444

[!] Identifying service...

[!] Puerto 53 -> (domain) open
[!] Puerto 80 -> (http) open
[!] Puerto 27998 -> open
[!] Puerto 37443 -> open
[!] Puerto 37444 -> open

[✓] Done


[!] Copying ports to clipboard...

[✓] Ports copied to clipboard
[✓] Done
```

```haskell
~$ ./mapper.sh -i 10.10.43.2 -p- -s -u -o output.txt

[✓] Default Max threads: 200

[✓] Output to file: output.txt

[✓] Possible Unix/Linux, TTL = 64.

[✓] Host is Mac

[!] No output

[✓] Service identifier

[✓] UDP scan


[!] Identifying service...

[!] Puerto 8080 -> open

[✓] Done
```