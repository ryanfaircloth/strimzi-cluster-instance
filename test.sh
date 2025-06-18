#!/bin/bash
#set -e
rm -rf .test || true
mkdir .test || true
# Fetch CA cert and import it into the correct truststore path
kubectl -n kafka get secret kafka-dev-sci-external -o json | jq '.data."ca.crt"' | tr -d '"' | base64 --decode > .test/ca.crt
keytool -import -trustcacerts -keystore .test/truststore.jks -storepass test123 -noprompt -file .test/ca.crt 
# -importcert -alias ca 

# JAAS_CONFIG=$(kubectl get secret obiwan -o json | jq '.data."sasl.jaas.config"' | tr -d '"' | base64 --decode)

cat <<EOF > .test/kafka-client-config.properties
bootstrap.servers=kafka-dev-bootstrap.domain.local:9094
# sasl.jaas.config=$JAAS_CONFIG
# security.protocol=SASL_SSL
security.protocol=SSL
# sasl.mechanism=SCRAM-SHA-512
ssl.truststore.location=$(pwd)/.test/truststore.jks
ssl.truststore.password=test123
EOF

# podman run -it --rm --network host \
#     -v $(pwd)/.test/:/tmp/ \
#     --add-host="kafka-dev-bootstrap.domain.local:127.0.0.1" \
#     quay.io/strimzi/kafka:0.46.0-kafka-4.0.0 \
#     bin/kafka-console-producer.sh \
#     --bootstrap-server kafka-dev-bootstrap.domain.local:9094 \
#     --topic my-topic \
#     --producer.config $(pwd)/.test/kafka-client-config.properties

# podman run -it --rm --network host \
#     -v $(pwd)/.test/:/tmp/ quay.io/strimzi/kafka:0.46.0-kafka-4.0.0 \
#     bin/kafka-console-consumer.sh \
#     --bootstrap-server kafka-dev-bootstrap.domain.local:9094 \
#     --topic my-topic \
#     --from-beginning \
#     --consumer.config $(pwd)/kafka-client-config.properties

./kafka_2.13-4.0.0/bin/kafka-console-producer.sh \
    --bootstrap-server kafka-dev-bootstrap.domain.local:9094 \
    --topic my-topic \
    --producer.config $(pwd)/.test/kafka-client-config.properties