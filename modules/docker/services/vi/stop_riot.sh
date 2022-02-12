docker ps | grep riot- | awk -F" " '{print $1}' | xargs docker kill
