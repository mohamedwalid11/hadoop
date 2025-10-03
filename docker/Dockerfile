# Use pre-built Hadoop/Spark image as base
FROM bitnami/spark:3.5.0

USER root

# Install additional tools
RUN apt-get update && \
    apt-get install -y wget curl ssh sudo python3-pip && \
    apt-get clean

# Install Kafka (much faster - just Kafka)
ENV KAFKA_VERSION=3.6.0
ENV KAFKA_HOME=/opt/kafka
RUN wget https://archive.apache.org/dist/kafka/3.6.0/kafka_2.13-3.6.0.tgz && \
    tar -xzf kafka_2.13-3.6.0.tgz -C /opt && \
    mv /opt/kafka_2.13-3.6.0 /opt/kafka && \
    rm kafka_2.13-3.6.0.tgz

# Install Hive (lightweight)
ENV HIVE_VERSION=3.1.3
ENV HIVE_HOME=/opt/hive
RUN wget https://archive.apache.org/dist/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz && \
    tar -xzf apache-hive-3.1.3-bin.tar.gz -C /opt && \
    mv /opt/apache-hive-3.1.3-bin /opt/hive && \
    rm apache-hive-3.1.3-bin.tar.gz

# Set paths
ENV PATH=/opt/spark/bin:/opt/kafka/bin:/opt/hive/bin:$PATH

# Python packages
RUN pip3 install jupyter pandas kafka-python confluent-kafka

# SSH setup
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys

COPY start-services.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-services.sh

EXPOSE 9870 8088 4040 10000 9092 2181

CMD ["/usr/local/bin/start-services.sh"]
