#!/bin/bash

#Usage: ./scrape_mongo.sh <mongo-collection> <es-index>

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "scrape_mongo.sh script located at: $SCRIPT_DIR"

if [ -z "$1" ]
then
        echo "No flightId provided."
        exit -1
fi

if [ -z "$2" ]
then
        echo "No es-index provided."
        exit -1
fi

echo "scraping mongo collection: $1 into es-index: $2"

echo "Generating mongodata.conf"

mongodata=$(cat << EOF
input {
        mongodb{
                uri => 'mongodb://logstash:logstash@mongo:27017/logui-db'
                placeholder_db_dir => '/opt/logstash-mongodb/'
                placeholder_db_name => 'logstash_sqlite.db'
                collection => '$1'
                batch_size => 5000
                parse_method => 'dig'
                dig_fields => ['eventDetails','nodes','paths', 'name', 'action','type','xpath','path','domSnapshot', 'timestamps','eventTimestamp', 'element']
        }
}
filter {
        mutate {
                remove_field => ["_id", "log_entry"]
        }
        mutate {
                gsub => ["metadata", "=>", ": "]
        }
}
output {
        stdout {
                codec => rubydebug
        }
        elasticsearch {
                action => "index"
                index => "$2"
                hosts => ["es-container:9200"]
        }
}
EOF)

echo "$mongodata"

echo "clearing any old logstash containers"

docker stop logstash || true && docker rm logstash || true

echo "running logstash"

echo "$mongodata" > $SCRIPT_DIR/config/mongodata.conf &&\
 docker run -d --name=logstash --network=logui_es-net -v $SCRIPT_DIR/config/:/usr/share/logstash/config/ -p 9600:9600 aianta/logstash bash -c "logstash -f /usr/share/logstash/config/mongodata.conf"  


