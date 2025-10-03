FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y openjdk-11-jdk wget ssh sudo python3 python3-pip netcat curl && \
    apt-get clean

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Hadoop 3.4.2
ENV HADOOP_VERSION=3.4.2
ENV HADOOP_HOME=/opt/hadoop
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

# Spark 4.0.1 - with fallback to archive
ENV SPARK_VERSION=4.0.1
ENV SPARK_HOME=/opt/spark
RUN (wget https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz || \
     wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz) && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} && \
    rm spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Hive 4.1.0
ENV HIVE_VERSION=4.1.0
ENV HIVE_HOME=/opt/hive
RUN wget https://dlcdn.apache.org/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    tar -xzf apache-hive-${HIVE_VERSION}-bin.tar.gz -C /opt && \
    mv /opt/apache-hive-${HIVE_VERSION}-bin ${HIVE_HOME} && \
    rm apache-hive-${HIVE_VERSION}-bin.tar.gz

# Kafka 4.1.0
ENV KAFKA_VERSION=4.1.0
ENV SCALA_VERSION=2.13
ENV KAFKA_HOME=/opt/kafka
RUN wget https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
    tar -xzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt && \
    mv /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} ${KAFKA_HOME} && \
    rm kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$HIVE_HOME/bin:$KAFKA_HOME/bin:$PATH
ENV HADOOP_CLASSPATH=$HADOOP_HOME/share/hadoop/tools/lib/*:$HADOOP_CLASSPATH

RUN find $HIVE_HOME/lib -name "guava-*.jar" -delete 2>/dev/null || true && \
    find $HADOOP_HOME/share/hadoop -name "guava-*.jar" | head -1 | xargs -I {} cp {} $HIVE_HOME/lib/ 2>/dev/null || echo "Guava fix skipped"

RUN cd $SPARK_HOME/jars && \
    (wget https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/4.0.1/spark-sql-kafka-0-10_2.12-4.0.1.jar || \
     wget https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.5.1/spark-sql-kafka-0-10_2.12-3.5.1.jar) && \
    wget https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/4.1.0/kafka-clients-4.1.0.jar && \
    wget https://repo1.maven.org/maven2/org/apache/commons/commons-pool2/2.12.0/commons-pool2-2.12.0.jar

RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys

COPY start-services.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-services.sh

RUN pip3 install pyspark jupyter pandas kafka-python confluent-kafka

EXPOSE 9870 8088 4040 10000 10002 9092 2181

CMD ["/usr/local/bin/start-services.sh"]
