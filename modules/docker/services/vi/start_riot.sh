if [[ -n $DB_NAME ]]
then
    DB_LABEL="-l db_name=$DB_NAME"
fi

if [[ -n $JOB_NAME ]]
then
    JOB_LABEL="-l job_name=$JOB_NAME"
fi

docker run -d $DB_LABEL $JOB_LABEL --rm \
 --name "riot-$1" \
 --net br0 riot \
/riot-redis/bin/riot-redis -h ${SOURCE_URL} -p ${SOURCE_PORT} ${SOURCE_PASSWORD} replicate ${TYPE_DS} -h ${DESTINATION_URL} -p ${DESTINATION_PORT} ${DESTINATION_PASSWORD} ${READER_PARAMS} --event-queue 100000 --mode live