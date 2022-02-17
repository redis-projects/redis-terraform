if [[ -n $1 ]]
then
    FILTER="-f label=$1"
fi

docker ps $FILTER | grep riot- | awk -F" " '{print $1}' | xargs docker kill
