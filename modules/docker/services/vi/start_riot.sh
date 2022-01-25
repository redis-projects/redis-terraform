docker run -d --rm \
-e SOURCE_URL="$2" \
-e SOURCE_PORT="$3" \
-e DESTINATION_URL="$4" \
-e DESTINATION_PORT="$5" \
-e NUM_THREADS="$6" \
 --name "riot-$1" --net br0 riot
