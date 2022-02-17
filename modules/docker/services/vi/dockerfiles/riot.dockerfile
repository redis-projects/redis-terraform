FROM openjdk:11
RUN apt-get install bash && \
    apt-get update && \
    apt-get install nano
RUN wget -O /riot-gen.zip https://github.com/redis-developer/riot/releases/download/v2.15.4/riot-gen-2.15.4.zip
RUN wget -O /riot-redis.zip https://github.com/redis-developer/riot/releases/download/v2.15.4/riot-redis-2.15.4.zip
RUN unzip -d /riot-gen/ /riot-gen.zip
RUN cd /riot-gen/ && mv riot-gen*/* .
RUN unzip -d /riot-redis/ /riot-redis.zip
RUN cd /riot-redis/ && mv riot-redis*/* .