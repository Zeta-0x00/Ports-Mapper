# Ports Mapper
Simple tool for port scanning and port service enumeration.

The reason for this tool is mainly to facilitate moments in security audits where it is known that map cannot be used for various reasons on the network.

The tool depends on 2 binaries on the host system, it needs to have netcat (nc) and ping, in order to proceed with the automation of service identification and the approximation of the possible operating system.

# Usage

```bash
~$ chmod +x mapper.sh
~$ ./mapper.sh <ip>
```

# Example of use


```haskell
~$ ./mapper.sh
[!] Usage:
	./mapper.sh <ip>

[!] Dependencies:
	nc
	ping
```

```haskell

~$ ./mapper.sh <ip>
Host Address = <ip>

[✓] Possible Unix/Linux, TTL = 64.

Port 53 -> Open
Port 80 -> Open

Open Ports =  53,80

[!] Puerto 53 -> (domain) is open
[!] Puerto 80 -> (http) is open

```