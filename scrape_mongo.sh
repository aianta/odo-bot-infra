#!/bin/bash

#Usage: ./scrape_mongo.sh <mongo-collection> <es-index>

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
        }
}
filter {
        mutate {
                remove_field => ["_id"]
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

echo "$mongodata" > ./config/mongodata.conf &&\
 docker run -d --network=logui_es-net -v $(pwd)/config/:/usr/share/logstash/config/ -p 9600:9600 aianta/logstash bash -c "logstash -f /usr/share/logstash/config/mongodata.conf"  


