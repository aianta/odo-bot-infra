FROM docker.elastic.co/logstash/logstash:8.4.3

RUN bash -c "bin/logstash-plugin install logstash-input-mongodb"

USER root
RUN mkdir /opt/logstash-mongodb/
RUN chown logstash:logstash /opt/logstash-mongodb/

CMD "logstash -f /usr/share/logstash/config/mongodata.conf"