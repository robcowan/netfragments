#!/bin/bash

#+
#  e.g. dorecon.sh -v -r $(cat targetlist.txt)
#-
if [ -z "$*" ]
then
   echo "Usage: dorecon.sh -v -q -r -p discover|enumerate|identify|intrude IP [IP]..." 1>&2
   exit 1
fi

THISCON=$(date +%R)

job_cnt=0
job_max=3
job_pids=""
result=0

verbose()
{
   if [ $f_verbose != 0 ]
   then
      echo -e "$1"
   fi
}

quiet()
{
   if [ $f_quiet != 1 ]
   then
      echo -e "$1"
   fi
}

int_trap()
{
   for pid in $job_pids
   do
      kill -9 $pid
   done
   exit 1
}

handle_jobs()
{
   if [ $job_cnt -lt $job_max ]
   then
      jobip="$ip"
      job_cnt=`expr $job_cnt + 1`
      eval $1 &
      job_pids="$job_pids $!"
      verbose "[ ] Queuing process: $! -- $1"
      result=1
   else
      my_pids="$job_pids"
      job_pids=""
      for pid in $my_pids
      do
         verbose "[ ] Processing process: $pid"
         if kill -0 $pid 2>/dev/null
         then
            verbose "[ ] Process running: $pid"
            job_pids="$job_pids $pid"
            result=0
         elif wait $pid
         then
            verbose "[ ] Ending process: $pid"
            job_cnt=`expr $job_cnt - 1`
            result=0
         else
            echo "[X] Ending process in error: $pid" 1>&2
            job_cnt=`expr $job_cnt - 1`
            result=$?
            result=0
         fi
      done
      let detract="$RANDOM % 15"
      sleep $detract
   fi
}

do_job()
{
   for job_name in $*
   do
      while :
      do
         handle_jobs $job_name
         if [[ $result -eq 1 ]]
         then
            break
         fi
      done
   done
}

job_snmpcheck()
{
   my_job="/pentest/enumeration/snmp/onesixtyone/onesixtyone -w 25 -c /pentest/enumeration/snmp/onesixtyone/dict.txt $jobip"
   quiet "[*] ($(date +%R)) Start: $my_job"
   $my_job > $jobip/snmpcheck.tmp
   quiet "[^] ($(date +%R)) Completed: $my_job\a"
   my_job="/pentest/enumeration/snmp/snmpcheck/snmpcheck-1.8.pl -t $jobip -"
   quiet "[*] ($(date +%R)) Start: $my_job"
   $my_job >> $jobip/snmpcheck.tmp
   quiet "[^] ($(date +%R)) Completed: $my_job\a"
   mv $jobip/snmpcheck.tmp $jobip/snmpcheck.txt }

job_httprint()
{
   my_job="/pentest/enumeration/web/httprint/linux/httprint -P0 -s /pentest/enumeration/web/httprint/linux/signatures.txt -h $ip"
   quiet "[*] ($(date +%R)) Start: $my_job"
   $my_job > $ip/httprint.tmp
   quiet "[^] ($(date +%R)) Completed: $my_job"
   grep Service $jobip/httprint.tmp >/dev/null 2>&1
   if [ $? -eq 0 ]
   then
      verbose "[x] ($(date +%R)) $my_job: Deleting empty results."
      rm -f $jobip/httprint.*
   else
      mv $jobip/httprint.tmp $jobip/httprint.txt
   fi
}

job_nbtscan()
{
   my_job="nbtscan -v $jobip"
   quiet "[*] ($(date +%R)) Start: $my_job"
   $my_job > $jobip/nbtscan.tmp
   quiet "[^] ($(date +%R)) Completed: $my_job\a"
   grep Service $jobip/nbtscan.tmp >/dev/null 2>&1
   if [ $? ]
   then
      verbose "[x] ($(date +%R)) $my_job: Deleting empty results."
      rm -f $jobip/nbtscan.*
   else
      mv $jobip/nbtscan.tmp $jobip/nbtscan.txt
   fi
}

job_nikto()
{
   if [[ -e $jobip/nikto.txt && $f_refresh -ne 1 ]]
   then
      return 1
   fi
   my_job="nmap -Pn -p$my_ports -sTV -oG - $jobip"
   quiet "[*] ($(date +%R)) Start: nikto $my_job"
   $my_job | /pentest/web/nikto/nikto.pl -config /pentest/web/nikto/nikto.conf -h - > $jobip/nikto.tmp
   quiet "[^] ($(date +%R)) Completed: nikto $jobip\a\a"
   grep " 0 host(s) tested" $jobip/nikto.tmp > /dev/null
   if [ $? ]
   then
      mv $jobip/nikto.tmp $jobip/nikto.txt
   else
      verbose "[x] nikto $jobip: Deleting empty results."
      rm -f $jobip/nikto.*
   fi
}

job_nmap_identify()
{
   my_job="nmap -vv -Pn -pT:0,T:2,T:21,T:22,T:23,T:25,T:53,T:80,T:110,T:111,T:113,T:135,T:137,T:139,T:143,T:443,T:445,T:993,T:995,T:1433,T:1434,T:3306,T:3389,T:4444,T:5900,T:5901,U:53,U:67,U:69,U:111,U:123,U:135,U:137,U:161,U:631,U:1433,U:1434 --dns-servers 192.168.13.220,192.168.13.221 -T4 -sSUV --defeat-rst-ratelimit --open --reason --version-all --script=\"nbstat,smb-mbenum,smb-security-mode,smb-enum-sessions,smb-os-discovery,smb-check-vulns,banner,ftp-anon,http-iis-webdav-vuln,snmp-win32-users,snmp-sysdescr,snmp-win32-services,snmp-interfaces,http-methods,http-headers,smb-enum-domains,smb-enum-users,smb-enum-sessions,dns-nsid,http-auth-finder,http-title\" --script-args=\"ntdomain=SHCSD\" --log-errors -oA $jobip/nmap_identify $jobip"
   quiet "[*] ($(date +%R)) Start: $my_job"
   eval $my_job > /dev/null
   quiet "[^] ($(date +%R)) Completed: nmap $jobip\a"
   rm -f $jobip/1_nmap_identify.html
   xsltproc $jobip/nmap_identify.xml -o $jobip/1_nmap_identify.html
   quiet "[^] ($(date +%R)) Completed: nmap $jobip to html\a"
}

job_nmap_full()
{
   my_job="nmap -vv -Pn -pT:0,U:2,$my_ports --dns-servers 192.168.13.220,192.168.13.221 -T2 -sTUV --reason --version-all -O --max-retries 15 --script=\"(default or auth or discovery or exploit or malware or version or vuln) and not http-google-malware and not http-grep and not http-domino-enum-passwords and not citrix-brute-xml and not dns-brute and not http-wordpress-* and not http-vhosts and not targets-asn and not broadcast\" --script-args=\"ntdomain=SHCSD,dns-client-subnet-scan.domain=shcsd.sharp.com\" --log-errors -oN $jobip/nmap.txt -oX $jobip/nmap.xml $jobip"
   quiet "[*] ($(date +%R)) Start: $my_job"
   eval $my_job > /dev/null
   quiet "[^] ($(date +%R)) Completed: nmap $jobip\a"
   rm -f $jobip/2_nmap.html
   xsltproc $jobip/nmap.xml -o $jobip/2_nmap.html
   quiet "[^] ($(date +%R)) Completed: nmap $jobip to html\a"
}


#+
#  Throw up unicorn for speedy all port scan and use ports for nmap
#-
job_unicornscan()
{
   my_job="unicornscan --packet-timeout 8 --repeats 3 -r 75 -m$1 $ip:a"
   quiet "[*] ($(date +%R)) Start: $my_job"
   $my_job >> $ip/unicorn.tmp
   quiet "[^] ($(date +%R)) Completed: $my_job\a"
}


do_discover()
{
   if [[ ! -e $ip/ports.nmap || f_refresh -eq 1 ]]
   then
      job_unicornscan T &
      unicorntcp_pid="$!"
      sleep 3
      job_unicornscan U
      wait $unicorntcp_pid
      grep "$ip" $ip/unicorn.tmp | sort | uniq > $ip/ports.unicorn      #  Sometimes we get icmp back from other ip's.. prolly with subprocess scanning.
      rm -f $ip/unicorn.tmp
      nmap -P0 -sU -p123 $ip -oG - | grep "123/open/" > /dev/null       #  Unicorn just sucks with ntp.. use nmap here to fix it up.
      if [[ ! $? ]]
      then
         echo "UDP open          unknown[  123]         from $ip  ttl 128" >> $ip/ports.unicorn
      fi
      my_ports="$(./unicorn-to-nmap-ports.pl $ip/ports.unicorn)"
      echo $my_ports > $ip/ports.nmap
   fi
   my_ports="$(cat $ip/ports.nmap)"
   if [[ -z "$my_ports" ]]
   then
      quiet "[=] ($(date +%R)) No responses from $ip"
      rm -f $ip/ports.unicorn
      rm -f $ip/ports.nmap
   else
      quiet "[=] ($(date +%R)) Open ports on $ip: $my_ports"
   fi
}

do_enumerate()
{
   do_job job_nbtscan
   if [[ "$my_ports" == *U:161* ]]
   then
      do_job job_snmpcheck
   fi
}

do_identify()
{
   do_job job_httprint job_nmap_identify
   if [[ "$my_ports" == *U:161* ]]
   then
      do_job job_nikto
   fi
}

do_intrude()
{
   do_job job_nmap_full
}


f_basename="."
f_verbose=0
f_phases=""
f_refresh=0
f_quiet=9

echo $@

set -- `getopt "vqrb:p:" "$@"`
echo $@
while [ $# -gt 0 ]
do
   case "$1" in
      -v)
         f_verbose=1
      ;;
      -b)
         f_basename="$2"
         shift
      ;;
      -p)
         f_phases=$2
         shift
      ;;
      -r)
         f_refresh=1
         echo "[*] ($(date +%R)) Data refresh is set -- overwriting previous data"
         sleep 3
      ;;
      -q)
         f_quiet=1
      ;;
      --)
         shift
         break
      ;;
      -*)
         echo "Unrecognized option $1" 1>&2
         exit 1
      ;;
      *)
         break
      ;;
   esac
   shift
done

if [ -z "$f_phases" ]
then
   f_phases="identify discover enumerate intrude"
fi
allhosts=$*

trap int_trap INT

for phase in $f_phases
do
   for ip in $allhosts
   do
      if [[ -e $ip/.no ]]
      then
         if [[ $f_verbose -eq 1 ]]
         then
            quiet "[x] ($(date +%R)) .no file exists; ignoring $ip"
         fi
         continue
      fi
#phase
         quiet "[*] ($(date +%R)) Starting $phase $ip"
         my_ports="$(cat $ip/ports.nmap)"

         if [[ ! -d "$ip" ]]
         then
            mkdir "$ip"
            verbose "[=] ($(date +%R)) New store created: $ip"
         fi

         case "$phase" in
            discover)
               do_discover
            ;;
            enumerate)
               do_enumerate
            ;;
            identify)
               do_identify
            ;;
            intrude)
               echo "my_ports: $my_ports"
               if [[ ! -z "$my_ports" ]]
               then
                  do_intrude
               fi
            ;;
            *)
               echo "Invalid phase: $phase" 1>&2
            ;;
         esac
         quiet "[*] ($(date +%R)) Ending $phase $ip"
   done # ip
   verbose "[*] ($(date +%R)) Waiting for end of phase"
   wait
done # phase

#  robc
#  nmap -PA -sVUTC -T5 -pT:21-23,25,53,80,110,143,443,3306,3389,8080,U:53,67,69,123,161,631,1434 -oG - --open -iL targetlist.txt
