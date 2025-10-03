#!/usr/bin/env python3

import time
from pyspark.sql import SparkSession
from kafka import KafkaProducer, KafkaConsumer
import json

print("Testing all services...")

# Test Spark with Hive
print("\n1. Testing Spark with Hive Support...")
spark = SparkSession.builder \
    .appName("TestAll") \
    .config("spark.sql.warehouse.dir", "/user/hive/warehouse") \
    .config("spark.sql.catalogImplementation", "hive") \
    .enableHiveSupport() \
    .getOrCreate()

try:
    # Create database and table
    spark.sql("CREATE DATABASE IF NOT EXISTS test_db")
    spark.sql("USE test_db")
    spark.sql("""
        CREATE TABLE IF NOT EXISTS test_table (
            id INT,
            message STRING
        ) STORED AS PARQUET
    """)
    spark.sql("INSERT INTO test_table VALUES (1, 'Hello from Hive')")
    spark.sql("SELECT * FROM test_table").show()
    print("✅ Spark with Hive is working!")
except Exception as e:
    print(f"❌ Spark/Hive error: {e}")

# Test Kafka
print("\n2. Testing Kafka...")
try:
    # Producer
    producer = KafkaProducer(
        bootstrap_servers='localhost:9092',
        value_serializer=lambda v: json.dumps(v).encode('utf-8')
    )
    
    # Send messages
    for i in range(5):
        message = {'number': i, 'message': f'Test message {i}'}
        producer.send('test-topic', value=message)
    producer.flush()
    print("✅ Kafka producer is working!")
    
    # Consumer
    consumer = KafkaConsumer(
        'test-topic',
        bootstrap_servers='localhost:9092',
        auto_offset_reset='earliest',
        value_deserializer=lambda m: json.loads(m.decode('utf-8')),
        consumer_timeout_ms=5000
    )
    
    messages = []
    for message in consumer:
        messages.append(message.value)
    
    if messages:
        print(f"✅ Kafka consumer is working! Received {len(messages)} messages")
    
except Exception as e:
    print(f"❌ Kafka error: {e}")

# Test Spark Streaming with Kafka
print("\n3. Testing Spark Structured Streaming with Kafka...")
try:
    # Read from Kafka
    df = spark \
        .readStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", "localhost:9092") \
        .option("subscribe", "test-topic") \
        .option("startingOffsets", "earliest") \
        .load()
    
    # Select key and value
    df_string = df.selectExpr("CAST(value AS STRING)")
    
    # Write to console
    query = df_string \
        .writeStream \
        .outputMode("append") \
        .format("console") \
        .trigger(processingTime='5 seconds') \
        .start()
    
    # Run for 10 seconds then stop
    time.sleep(10)
    query.stop()
    print("✅ Spark Streaming with Kafka is working!")
    
except Exception as e:
    print(f"❌ Spark Streaming error: {e}")

spark.stop()
print("\n✅ All tests completed!")
