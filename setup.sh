#!/bin/bash

echo "🚀 Starting Kafka + Spark + Hive setup in Codespace..."

# Create necessary directories
mkdir -p data hive-data

# Start all services
echo "🐳 Starting Docker Compose services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to initialize..."
sleep 30

# Create a Kafka topic for our example
echo "📦 Creating Kafka topic 'sensor-data'..."
docker-compose exec kafka kafka-topics --create --topic sensor-data --bootstrap-server kafka:9092 --partitions 1 --replication-factor 1

# Initialize Hive
echo "🐝 Initializing Hive metastore..."
docker-compose exec hive-metastore schematool -initSchema -dbType postgres

# Create sample Hive table
echo "📋 Creating sample Hive table..."
cat > create_table.hql <<EOF
CREATE DATABASE IF NOT EXISTS iot;
USE iot;
CREATE TABLE IF NOT EXISTS sensor_readings (
    sensor_id STRING,
    temperature DOUBLE,
    humidity DOUBLE,
    timestamp BIGINT
)
STORED AS PARQUET;
EOF

docker-compose exec hive-server beeline -u jdbc:hive2://localhost:10000 -f /workspace/create_table.hql

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
pip install kafka-python pyspark pyhive

# Create a simple test script
cat > test_setup.py <<EOF
from kafka import KafkaProducer
from pyspark.sql import SparkSession
import time
import json

# Test Kafka
print("Testing Kafka connection...")
producer = KafkaProducer(bootstrap_servers='localhost:9092')
producer.send('sensor-data', json.dumps({"sensor_id": "test", "temperature": 25.0, "humidity": 60.0, "timestamp": int(time.time())}).encode('utf-8'))
producer.close()
print("✅ Kafka test successful")

# Test Spark
print("Testing Spark connection...")
spark = SparkSession.builder \
    .appName("Test") \
    .config("spark.sql.warehouse.dir", "/workspace/hive-data/warehouse") \
    .enableHiveSupport() \
    .getOrCreate()
spark.sql("SHOW DATABASES").show()
spark.stop()
print("✅ Spark test successful")

# Test Hive
print("Testing Hive connection...")
from pyhive import hive
conn = hive.Connection(host="localhost", port=10000, username="root")
cursor = conn.cursor()
cursor.execute("SHOW DATABASES")
print(cursor.fetchall())
conn.close()
print("✅ Hive test successful")

print("\n🎉 All systems operational! You're ready to go!")
EOF

echo "✅ Setup complete!"
echo ""
echo "Useful commands:"
echo "  - View Kafka logs: docker-compose logs kafka"
echo "  - Access Spark UI: http://localhost:8080 (in Codespace ports tab)"
echo "  - Connect to Hive: beeline -u jdbc:hive2://localhost:10000"
echo "  - Run test: python test_setup.py"
echo ""
echo "Check the examples directory for sample code!"
