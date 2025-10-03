#!/usr/bin/env python3

print("Testing Hadoop and Spark setup...")

# Test PySpark
try:
    from pyspark.sql import SparkSession
    spark = SparkSession.builder.appName("Test").getOrCreate()
    print("✅ Spark is working!")
    
    # Create a simple DataFrame
    data = [("Alice", 25), ("Bob", 30), ("Charlie", 35)]
    df = spark.createDataFrame(data, ["Name", "Age"])
    
    print("\nSample DataFrame:")
    df.show()
    
    spark.stop()
except Exception as e:
    print(f"❌ Spark error: {e}")

# Test HDFS
import subprocess
import os

try:
    # Create a test file
    with open("/tmp/test.txt", "w") as f:
        f.write("Hello Hadoop!")
    
    # Put file in HDFS
    subprocess.run(["hdfs", "dfs", "-mkdir", "-p", "/test"], check=True)
    subprocess.run(["hdfs", "dfs", "-put", "-f", "/tmp/test.txt", "/test/"], check=True)
    
    # List files
    result = subprocess.run(["hdfs", "dfs", "-ls", "/test/"], 
                          capture_output=True, text=True)
    
    if "test.txt" in result.stdout:
        print("✅ HDFS is working!")
    else:
        print("❌ HDFS error")
        
except Exception as e:
    print(f"❌ HDFS error: {e}")
