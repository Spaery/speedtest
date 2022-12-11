#!/bin/sh
# These values can be overwritten with env variables
LOOP="${LOOP:-false}"
LOOP_DELAY="${LOOP_DELAY:-60}"
DB_SAVE="${DB_SAVE:-false}"
DB_HOST="${DB_HOST:-http://localhost:8086}"
DB_ORG="${DB_ORG:-speedtest}"
DB_NAME="${DB_NAME:-speedtest}"
DB_USERNAME="${DB_USERNAME:-admin}"
DB_PASSWORD="${DB_PASSWORD:-password}"

run_speedtest()
{
    DATE=$(date +%s)
    HOSTNAME=$(hostname)

    # Start speed test
    echo "Running a Speed Test..."
    JSON=$(speedtest --accept-license --accept-gdpr -f json)
    DOWNLOAD="$(((echo $JSON | jq -r '.download.bandwidth') * 8))" # Download Speed in bits/sec
    UPLOAD="$(((echo $JSON | jq -r '.upload.bandwidth') * 8))" # Upload Speed in bits/ sec
    PING="$(echo $JSON | jq -r '.ping.latency')" # Latency in milliseconds
    echo "Your download speed is $(($DOWNLOAD  / 125000 )) Mbps ($(( $DOWNLOAD / 8 )) Bytes/s)."
    echo "Your upload speed is $(($UPLOAD  / 125000 )) Mbps ($(( $UPLOAD / 8 )) Bytes/s)."
    echo "Your ping is $PING ms."

    # Save results in the database
    if $DB_SAVE; 
    then
        echo "Saving values to database..."
        curl --request POST \
		"http://$DB_HOST/api/v2/write?org=$DB_ORG&bucket=$DB_NAME&precision=ns" \
  		--header "Authorization: Token $API_TOKEN" \
  		--header "Content-Type: text/plain; charset=utf-8" \
  		--header "Accept: application/json" \
  		--data-binary "
 			download,host=$HOSTNAME value=$DOWNLOAD
   			upload,host=$HOSTNAME value=$UPLOAD
   			ping,host=$HOSTNAME value=$PING
    		"
        echo "Values saved."
    fi
}

if $LOOP;
then
    while :
    do
        run_speedtest
        echo "Running next test in ${LOOP_DELAY}s..."
        echo ""
        sleep $LOOP_DELAY
    done
else
    run_speedtest   
fi
