docker run -d --rm \
-e SOURCE_URL="$2" \
-e SOURCE_PORT="$3" \
 --name "riot-gen-$1" --net br0 riot-gen
