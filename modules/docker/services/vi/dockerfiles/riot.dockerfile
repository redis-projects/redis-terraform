FROM gradle:jdk16-hotspot
RUN apt-get install bash && \
    apt-get update && \
    apt-get install nano
RUN wget https://github.com/redis-developer/riot/releases/download/v2.14.6/riot-gen-2.14.6.zip
RUN wget https://github.com/redis-developer/riot/releases/download/v2.14.6/riot-redis-2.14.6.zip
RUN unzip riot-gen-2.14.6.zip
RUN unzip riot-redis-2.14.6.zip
RUN cd riot-gen-2.14.6


