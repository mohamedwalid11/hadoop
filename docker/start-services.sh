#!/bin/bash
set -e

# Generate Kafka cluster ID if not exists
CLUSTER_ID_FILE="/tmp/kafka-cluster-id"
if [ ! -f "$CLUSTER_ID_FILE" ]; then
  KAFKA_CLUSTER_ID=$($KAFKA_HOME/bin/kafka-storage.sh random-uuid)
  echo "$KAFKA_CLUSTER_ID" > "$CLUSTER_ID_FILE"
else
  KAFKA_CLUSTER_ID=$(cat "$CLUSTER_ID_FILE")
fi

# Create Kafka data directory
KAFKA_LOG_DIR="/tmp/kafka-logs"
mkdir -p "$KAFKA_LOG_DIR"

# Create minimal KRaft config
KRAFT_CONFIG="/tmp/server.properties"
cat > "$KRAFT_CONFIG" <<EOF
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@localhost:9093
listeners=PLAINTEXT://:9092,CONTROLLER://:9093
advertised.listeners=PLAINTEXT://localhost:9092
controller.listener.names=CONTROLLER
inter.broker.listener.name=PLAINTEXT
log.dirs=$KAFKA_LOG_DIR
EOF

# Format storage if not already formatted
if [ ! -d "$KAFKA_LOG_DIR/meta.properties" ]; then
  $KAFKA_HOME/bin/kafka-storage.sh format -t "$KAFKA_CLUSTER_ID" -c "$KRAFT_CONFIG"
fi

# Start Kafka in foreground
exec $KAFKA_HOME/bin/kafka-server-start.sh "$KRAFT_CONFIG"
