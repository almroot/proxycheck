#!/bin/bash

# configuration
threads=128
corpusfile="/tmp/proxies.txt"
benchmark1="http://example.com/"
benchmark2="https://example.com/"

# callbacks where each must return a list of IP:port pairs
list01 () { curl 'https://api.proxyscrape.com/v2/?request=getproxies&protocol=http&timeout=10000&country=all&ssl=all&anonymity=all' --silent; }
list02 () { curl 'https://github.com/jetkai/proxy-list/blob/main/archive/txt/proxies-http.txt' --silent; }
list03 () { curl 'https://github.com/jetkai/proxy-list/blob/main/archive/txt/proxies-https.txt' --silent; }
list04 () { curl 'https://github.com/jetkai/proxy-list/blob/main/online-proxies/txt/proxies-http.txt' --silent; }
list05 () { curl 'https://github.com/jetkai/proxy-list/blob/main/online-proxies/txt/proxies-https.txt' --silent; }
list06 () { curl 'https://multiproxy.org/txt_all/proxy.txt' --silent; }
list07 () { curl 'https://proxylist.geonode.com/api/proxy-list?limit=500&page=1&sort_by=lastChecked&sort_type=desc&protocols=http%2Chttps' --silent | jq -c '.data[] | "\(.ip):\(.port)"' | cut '-d"' -f2; }
list08 () { curl 'https://proxylist.geonode.com/api/proxy-list?limit=500&page=2&sort_by=lastChecked&sort_type=desc&protocols=http%2Chttps' --silent | jq -c '.data[] | "\(.ip):\(.port)"' | cut '-d"' -f2; }
list09 () { curl 'https://proxylist.geonode.com/api/proxy-list?limit=500&page=3&sort_by=lastChecked&sort_type=desc&protocols=http%2Chttps' --silent | jq -c '.data[] | "\(.ip):\(.port)"' | cut '-d"' -f2; }
list10 () { curl 'https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt' --silent; }
list11 () { curl 'https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/https.txt' --silent; }
list12 () { curl 'https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt' --silent; }
list13 () { curl 'https://raw.githubusercontent.com/almroot/proxylist/master/list.txt' --silent; }
list14 () { curl 'https://raw.githubusercontent.com/clarketm/proxy-list/master/proxy-list-raw.txt' --silent; }
list15 () { curl 'https://raw.githubusercontent.com/hendrikbgr/Free-Proxy-Repo/master/proxy_list.txt' --silent; }
list16 () { curl 'https://raw.githubusercontent.com/mmpx12/proxy-list/master/https.txt' --silent; }
list17 () { curl 'https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/http.txt' --silent; }
list18 () { curl 'https://raw.githubusercontent.com/monosans/proxy-list/main/proxies_anonymous/http.txt' --silent; }
list19 () { curl 'https://raw.githubusercontent.com/proxy4parsing/proxy-list/main/http.txt' --silent; }
list20 () { curl 'https://raw.githubusercontent.com/proxy4parsing/proxy-list/main/http_old.txt' --silent; }
list21 () { curl 'https://raw.githubusercontent.com/roosterkid/openproxylist/main/HTTPS_RAW.txt' --silent; }
list22 () { curl 'https://raw.githubusercontent.com/sunny9577/proxy-scraper/master/proxies.txt' --silent; }
list23 () { curl 'https://raw.githubusercontent.com/zeynoxwashere/proxy-list/main/http.txt' --silent; }

# fetch proxy server candidates
rm "$corpusfile" 2>/dev/null
{
  list01;
  list02;
  list03;
  list04;
  list05;
  list06;
  list07;
  list08;
  list09;
  list10;
  list11;
  list12;
  list13;
  list14;
  list15;
  list16;
  list17;
  list18;
  list19;
  list20;
  list21;
  list22;
  list23;
} > "$corpusfile"

# we need to know how some web servers respond to eliminate bad (malicious) servers
checksum1=$( curl --silent "$benchmark1" | md5sum | cut '-d ' -f1 )
checksum2=$( curl --silent "$benchmark2" | md5sum | cut '-d ' -f1 )

# this function will be called asynchronously and is used to validate the integrity of the proxies
check () { 
  proxy="$1"; benchmark1="$2"; benchmark2="$3"; checksum1="$4"; checksum2="$5"
  result1=$( curl --connect-timeout 2 --max-time 5 --silent -x "$proxy" "$benchmark1" | md5sum | cut '-d ' -f1; )
  if [[ "$result1" != "$checksum1" ]]; then
    echo "got $result1, expected $checksum1 for $proxy" 1>&2;
    return
  fi
  result2=$( curl --connect-timeout 2 --max-time 5 --silent -x "$proxy" "$benchmark2" | md5sum | cut '-d ' -f1; )
  if [[ "$result2" != "$checksum2" ]]; then
    echo "got $result2, expected $checksum2 for $proxy" 1>&2;
    return
  fi
  echo "$proxy"
}
export -f check

# iterate over each and every proxy and run check in parallel
sort < "$corpusfile" | \
grep -Po '(\d+\.){3}\d+:\d+' | \
uniq | \
shuf | \
xargs -n 1 -P "$threads" -I {} \
bash -c "check '{}' '$benchmark1' '$benchmark2' '$checksum1' '$checksum2'"
