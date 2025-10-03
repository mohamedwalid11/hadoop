#!/bin/bash

echo "Starting services..."

# Start SSH
service ssh start

# Configure Hadoop
echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Create Hadoop config files
cat > $HADOOP_HOME/etc/hadoop/core-site.xml <<EOF
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF

cat > $HADOOP_HOME/etc/hadoop/hdfs-site.xml <<EOF
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
EOF

# Create Hive configuration
mkdir -p $HIVE_HOME/conf
cat > $HIVE_HOME/conf/hive-site.xml <<EOF
<configuration>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:derby:;databaseName=/tmp/metastore_db;create=true</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>org.apache.derby.jdbc.EmbeddedDriver</value>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/user/hive/warehouse</value>
    </property>
    <property>
        <name>hive.exec.local.scratchdir</name>
        <value>/tmp/hive</value>
    </property>
</configuration>
EOF

# Kafka configuration
cat > $KAFKA_HOME/config/server.properties <<EOF
broker.id=0
listeners=PLAINTEXT://localhost:9092
log.dirs=/tmp/kafka-logs
num.partitions=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
zookeeper.connect=localhost:2181
EOF

# Format namenode (only if not already formatted)
if [ ! -d "/tmp/hadoop-root" ]; then
    hdfs namenode -format -force
fi

# Start Hadoop
start-dfs.sh
start-yarn.sh

# Wait for HDFS to be ready
echo "Waiting for HDFS to start..."
sleep 10

# Create Hive directories in HDFS
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod 777 /user/hive/warehouse
hdfs dfs -mkdir -p /tmp
hdfs dfs -chmod 777 /tmp

# Initialize Hive schema (only if not already done)
if [ ! -d "/tmp/metastore_db" ]; then
    echo "Initializing Hive Metastore..."
    $HIVE_HOME/bin/schematool -dbType derby -initSchema
fi

# Start Kafka Zookeeper
echo "Starting Zookeeper..."
$KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties
sleep 5

# Start Kafka Broker
echo "Starting Kafka..."
$KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties
sleep 5

# Create a test Kafka topic
$KAFKA_HOME/bin/kafka-topics.sh --create --topic test-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 2>/dev/null

echo "==============================================="
echo "All services started!"
echo "==============================================="
echo "Hadoop NameNode: http://localhost:9870"
echo "YARN ResourceManager: http://localhost:8088"
echo "Spark UI (when job runs): http://localhost:4040"
echo "Kafka Broker: localhost:9092"
echo "==============================================="
echo "Quick tests:"
echo "  - Hive: hive"
echo "  - Spark with Hive: spark-shell --conf spark.sql.catalogImplementation=hive"
echo "  - Kafka: kafka-topics.sh --list --bootstrap-server localhost:9092"
echo "==============================================="

# Keep container running
tail -f /dev/null
