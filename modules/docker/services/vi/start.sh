sudo yum install gettext

docker build -t riot -f dockerfiles/riot.dockerfile .

docker build -t riot-gen -f dockerfiles/riot-gen.dockerfile .
