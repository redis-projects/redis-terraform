FILE_LEN=$(grep -c '^' $1 | awk '{print $1}')
while IFS="" read -r p || [ -n "$p" ]
do
    echo "$(bash start_riot.sh $p)"
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