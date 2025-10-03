from pyspark.sql import SparkSession
from pyspark.sql.functions import *

spark = SparkSession.builder \
    .appName("KafkaSparkStream") \
    .config("spark.sql.adaptive.enabled", "false") \
    .getOrCreate()

# Read stream from Kafka
df = spark \
    .readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "test-topic") \
    .option("startingOffsets", "latest") \
    .load()

# Parse JSON from value
df_parsed = df.select(
    col("timestamp"),
    from_json(col("value").cast("string"), "value INT, message STRING").alias("data")
).select(
    col("timestamp"),
    col("data.value").alias("value"),
    col("data.message").alias("message")
)

# Write to console
query = df_parsed \
    .writeStream \
    .outputMode("append") \
    .format("console") \
    .option("truncate", False) \
    .trigger(processingTime='2 seconds') \
    .start()

query.awaitTermination()
