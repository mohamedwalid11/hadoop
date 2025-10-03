#!/bin/bash

# This script creates example files after docker-compose is running

echo "Creating example files..."

# Create examples directory
mkdir -p examples

# Kafka Producer Example
cat > examples/kafka-producer.py << 'EOF'
from kafka import KafkaProducer
import json
import time
import random

producer = KafkaProducer(
    bootstrap_servers='localhost:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

sensor_ids = ['sensor-001', 'sensor-002', 'sensor-003']

print("Starting Kafka producer... Press Ctrl+C to stop")
try:
    while True:
        data = {
            'sensor_id': random.choice(sensor_ids),
            'temperature': round(random.uniform(20.0, 35.0), 2),
            'humidity': round(random.uniform(30.0, 80.0), 2),
            'timestamp': int(time.time())
        }
        producer.send('sensor-data', data)
        print(f"Sent: {data}")
        time.sleep(2)
except KeyboardInterrupt:
    print("Stopping producer...")
finally:
    producer.close()
EOF

# Spark Consumer Example
cat > examples/spark-consumer.py << 'EOF'
from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, LongType

spark = SparkSession.builder \
    .appName("KafkaToHive") \
    .config("spark.sql.warehouse.dir", "/opt/hive/data/warehouse") \
    .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.0") \
    .config("hive.metastore.uris", "thrift://localhost:9083") \
    .enableHiveSupport() \
    .getOrCreate()

schema = StructType([
    StructField("sensor_id", StringType(), True),
    StructField("temperature", DoubleType(), True),
    StructField("humidity", DoubleType(), True),
    StructField("timestamp", LongType(), True)
])

df = spark \
    .readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "sensor-data") \
    .load()

parsed_df = df.select(
    from_json(col("value").cast("string"), schema).alias("data")
).select("data.*")

# Create database and table
spark.sql("CREATE DATABASE IF NOT EXISTS iot")
spark.sql("""
    CREATE TABLE IF NOT EXISTS iot.sensor_readings (
        sensor_id STRING,
        temperature DOUBLE,
        humidity DOUBLE,
        timestamp BIGINT
    )
    STORED AS PARQUET
""")

def foreach_batch_function(df, epoch_id):
    df.write.mode("append").insertInto("iot.sensor_readings")

query = parsed_df.writeStream \
    .foreachBatch(foreach_batch_function) \
    .outputMode("append") \
    .trigger(processingTime='10 seconds') \
    .start()

print("Starting Spark streaming job...")
query.awaitTermination()
EOF

# Hive Query Example
cat > examples/hive-query.sql << 'EOF'
SHOW DATABASES;
USE iot;
SHOW TABLES;

SELECT 
    sensor_id,
    AVG(temperature) as avg_temp,
    AVG(humidity) as avg_humidity,
    COUNT(*) as readings_count
FROM sensor_readings
GROUP BY sensor_id
ORDER BY avg_temp DESC;

SELECT * FROM sensor_readings ORDER BY timestamp DESC LIMIT 10;
EOF

# Test Script
cat > test-connection.py << 'EOF'
import time
from kafka import KafkaProducer
from pyhive import hive

print("Testing Kafka...")
try:
    producer = KafkaProducer(bootstrap_servers='localhost:9092')
    producer.send('test-topic', b'test message')
    producer.close()
    print("✅ Kafka connected")
except Exception as e:
    print(f"❌ Kafka failed: {e}")

print("Testing Hive...")
try:
    conn = hive.Connection(host="localhost", port=10000, username="root")
    cursor = conn.cursor()
    cursor.execute("SHOW DATABASES")
    print(f"✅ Hive connected. Databases: {cursor.fetchall()}")
    conn.close()
except Exception as e:
    print(f"❌ Hive failed: {e}")
EOF

# Install Python dependencies in workspace
pip install kafka-python pyspark pyhive

echo "✅ Examples created! Now run:"
echo "1. docker-compose up -d"
echo "2. docker-compose exec kafka kafka-topics --create --topic sensor-data --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1"
echo "3. python examples/kafka-producer.py"
echo "4. python examples/spark-consumer.py (in another terminal)"
echo "5. docker-compose exec hive-server beeline -u jdbc:hive2://localhost:10000 -f /workspace/examples/hive-query.sql"
