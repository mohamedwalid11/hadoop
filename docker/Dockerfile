FROM ubuntu:22.04

# Prevent prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Install Java and tools
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk wget ssh sudo python3 python3-pip && \
    apt-get clean

# Set Java environment
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Hadoop
ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/opt/hadoop
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

# Install Spark
ENV SPARK_VERSION=3.5.1
ENV SPARK_HOME=/opt/spark
RUN wget https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} && \
    rm spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Add to PATH
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$PATH

# Setup SSH (required for Hadoop)
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys

# Copy startup script
COPY start-services.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-services.sh

# Install PySpark
RUN pip3 install pyspark jupyter pandas

# Expose ports
EXPOSE 9870 8088 4040

CMD ["/usr/local/bin/start-services.sh"]
