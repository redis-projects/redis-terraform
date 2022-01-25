FROM gradle:jdk16-hotspot
RUN apt-get install bash && \
    apt-get update && \
    apt-get install nano
RUN wget https://github.com/redis-developer/riot/releases/download/v2.14.6/riot-gen-2.14.6.zip
RUN wget https://github.com/redis-developer/riot/releases/download/v2.14.6/riot-redis-2.14.6.zip
RUN unzip riot-gen-2.14.6.zip
RUN unzip riot-redis-2.14.6.zip
RUN cd riot-gen-2.14.6

ARG SOURCE_URL
ENV SOURCE_URL="${SOURCE_URL}"

ARG SOURCE_PORT
ENV SOURCE_PORT="${SOURCE_PORT}"

ARG DESTINATION_URL
ENV DESTINATION_URL="${DESTINATION_URL}"

ARG DESTINATION_PORT
ENV DESTINATION_PORT="${DESTINATION_PORT}"

ARG NUM_THREADS
ENV NUM_THREADS="${NUM_THREADS}"

CMD ["sh", "-c", "/home/gradle/riot-redis-2.14.6/bin/riot-redis -h ${SOURCE_URL} -p ${SOURCE_PORT} replicate --type ds -h ${DESTINATION_URL} -p ${DESTINATION_PORT} --mode live --threads ${NUM_THREADS}"]

