# Use pre-built Hadoop/Spark image as base
FROM bitnami/spark:3.5.0

USER root

# Install additional tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget curl ssh sudo python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Kafka (KRaft mode - no ZooKeeper needed)
ENV KAFKA_VERSION=3.6.0
ENV KAFKA_HOME=/opt/kafka
RUN wget https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_2.13-${KAFKA_VERSION}.tgz && \
    tar -xzf kafka_2.13-${KAFKA_VERSION}.tgz -C /opt && \
    mv /opt/kafka_2.13-${KAFKA_VERSION} ${KAFKA_HOME} && \
    rm kafka_2.13-${KAFKA_VERSION}.tgz

# Set PATH (prepend Kafka bin to existing PATH)
ENV PATH="${KAFKA_HOME}/bin:${PATH}"

# Install Python packages
RUN pip3 install jupyter pandas kafka-python confluent-kafka

# SSH setup
RUN mkdir -p /root/.ssh && \
    ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys

# Copy startup script
COPY start-services.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-services.sh

# Expose ports:
# 9092 - Kafka
# 4040 - Spark UI
EXPOSE 9092 4040

CMD ["/usr/local/bin/start-services.sh"]
