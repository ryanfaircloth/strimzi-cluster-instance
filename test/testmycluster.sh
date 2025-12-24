#!/bin/bash
kubectl -n kafka apply -f topic.yaml 
rm ./tmp/*
kubectl -n cert-manager get secret cluster-root-secret -o json | jq '.data."ca.crt"' | tr -d '"' | base64 --decode > ./tmp/ca.crt
keytool -importcert -alias ca -file ./tmp/ca.crt -keystore ./tmp/strimzi-kafka-truststore.jks -storepass nimda123

JAAS_CONFIG=$(kubectl -n kafka get secret admin -o json | jq '.data."sasl.jaas.config"' | tr -d '"' | base64 --decode)

cat <<EOF > ./tmp/kafka-client-config.properties
bootstrap.servers=bootstrap.strimzi.gateway.api.test:9094
sasl.jaas.config=$JAAS_CONFIG
security.protocol=SASL_SSL
sasl.mechanism=SCRAM-SHA-512
ssl.truststore.location=/tmp/strimzi-kafka-truststore.jks
ssl.truststore.password=nimda123
EOF

exit 0

podman run -it --rm --network host \
    -v $PWD/tmp/:/tmp/ quay.io/strimzi/kafka:0.42.0-kafka-3.7.1 \
    bin/kafka-console-producer.sh \
    --bootstrap-server bootstrap.strimzi.gateway.api.test:9094 \
    --topic my-topic \
    --producer.config /tmp/kafka-client-config.properties

 podman run -it --rm --network host \
    -v $PWD/tmp/:/tmp/ quay.io/strimzi/kafka:0.42.0-kafka-3.7.1 \
    bin/kafka-console-consumer.sh \
    --bootstrap-server bootstrap.strimzi.gateway.api.test:9094 \
    --topic my-topic \
    --consumer.config /tmp/kafka-client-config.properties   