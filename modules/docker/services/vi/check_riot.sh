RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'

for i in $(docker ps --format '{{.Names}}' | grep riot | sort); do
    error_count=$(docker logs $i 2>&1 | grep -v Asynchronous | grep error | wc -l)
    if [ "$error_count" -gt "0" ]
    then
      echo -e "Checking $i:  ${RED}$error_count errors${NC}"
    else
      scanned=$(docker logs $i 2>&1 | grep Scan | awk -F"?" '{print $1}')
      if [ -n "${scanned}" ]; 
      then 
        echo "Checking $i"
        echo "${scanned}";
      else
        echo -e "Checking $i:  ${GREEN}No transfers found!${NC}"
      fi
    fi
done
