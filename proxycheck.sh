#!/bin/bash

# configuration
threads=128
corpusfile="/tmp/proxies.txt"
benchmark1="http://example.com/"
benchmark2="https://example.com/"

# callbacks where each must return a list of IP:port pairs
list1 () { curl 'https://api.proxyscrape.com/v2/?request=getproxies&protocol=http&timeout=10000&country=all&ssl=all&anonymity=all' --silent; }
list2 () { curl 'https://proxylist.geonode.com/api/proxy-list?limit=1000&page=1&sort_by=lastChecked&sort_type=desc&protocols=http%2Chttps' --silent | jq -c '.data[] | "\(.ip):\(.port)"' | cut '-d"' -f2; }
list3 () { curl 'https://proxylist.geonode.com/api/proxy-list?limit=1000&page=2&sort_by=lastChecked&sort_type=desc&protocols=http%2Chttps' --silent | jq -c '.data[] | "\(.ip):\(.port)"' | cut '-d"' -f2; }
list4 () { curl 'https://proxylist.geonode.com/api/proxy-list?limit=1000&page=3&sort_by=lastChecked&sort_type=desc&protocols=http%2Chttps' --silent | jq -c '.data[] | "\(.ip):\(.port)"' | cut '-d"' -f2; }
list5 () { curl 'https://raw.githubusercontent.com/clarketm/proxy-list/master/proxy-list-raw.txt' --silent; }
list6 () { curl 'https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt' --silent; }
list7 () { curl 'https://github.com/ShiftyTR/Proxy-List/blob/master/http.txt' --silent; }
list8 () { curl 'https://github.com/ShiftyTR/Proxy-List/blob/master/https.txt' --silent; }
list9 () { curl 'https://github.com/monosans/proxy-list/blob/main/proxies_anonymous/http.txt' --silent; }
list10 () { curl 'https://multiproxy.org/txt_all/proxy.txt' --silent; }

# fetch proxy server candidates
rm "$corpusfile" 2>/dev/null
{
  list1;
  list2;
  list3;
  list4;
  list5;
  list6;
  list7;
  list8;
  list9;
  list10;
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
