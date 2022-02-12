: ${SLEEP?"Please set environment variable SLEEP to sleep time between batches"}
: ${BATCH_SIZE?"Please set environment variable BATCH_SIZE to how many instances to kick off in each batch"}

FILE_LEN=$(grep -c '^' $1 | awk '{print $1}')
while IFS="" read -r p || [ -n "$p" ]
do
    echo "Executing $p"
    # $p could look like NUM_THREADS=4 SOURCE_PORT=6379 SOURCE_URL=source.ec.com DESTINATION_PORT=10006 DESTINATION_URL=redis-10006.re.com TYPE_DS="--type ds" bash start_riot.sh job-1
    bash -c "$p"
    let "COUNT=COUNT+1"
    let "LINE_NO=LINE_NO+1"

    if [ "$COUNT" -ge "$BATCH_SIZE" ] 
    then     
        if [ "$LINE_NO" -lt "$FILE_LEN" ] 
        then
            echo "sleeping for $SLEEP seconds"
            sleep $SLEEP
        fi
        let "COUNT=0"
    fi
done < $1