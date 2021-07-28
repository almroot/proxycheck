# proxycheck
A bash script that scrapes various proxy feeds and asynchronously validates them

# usage

Valid results are printed to STDOUT, bad results goes to STDERR.

Example:
```
almroot@x:~$ ./proxycheck.sh 2>/dev/null
11.14.41.254:8080
22.96.123.239:3129
33.80.125.24:8080
44.2.212.129:999
55.38.121.1:8080
51.195.3.1:8080
223.87.106.2:3128
51.192.203.3:8080
...
```
