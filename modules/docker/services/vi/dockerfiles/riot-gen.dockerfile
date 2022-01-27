FROM riot

CMD ["sh", "-c", "/home/gradle/riot-gen-2.14.6/bin/riot-gen -h ${SOURCE_URL} -p ${SOURCE_PORT} import field=\"lorem.sentence(50)\" key=\"#index\" --end 2000000 set --keys key --field field --format RAW --keyspace string"]
