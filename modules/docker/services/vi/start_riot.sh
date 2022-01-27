docker run -d --rm \
 --name "riot-$1" \
 --net br0 riot \
/home/gradle/riot-redis-2.14.6/bin/riot-redis -h ${SOURCE_URL} -p ${SOURCE_PORT} replicate --type ds -h ${DESTINATION_URL} -p ${DESTINATION_PORT} --batch 1000 --event-queue 100000 --mode live --threads ${NUM_THREADS}