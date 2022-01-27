docker run -d --rm \
 --name "riot-gen-$1" \
 --net br0 riot \
/home/gradle/riot-gen-2.14.6/bin/riot-gen -h ${SOURCE_URL} -p ${SOURCE_PORT} import field='lorem.sentence(50)' key='#index' --end 2000000 set --keys key --field field --format RAW --keyspace string
