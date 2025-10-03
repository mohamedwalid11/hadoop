#!/bin/bash

echo "Starting services..."

# Start SSH
service ssh start

# Configure Hadoop (minimal setup)
echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Create config files
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

# Format namenode (only if not already formatted)
if [ ! -d "/tmp/hadoop-root" ]; then
    hdfs namenode -format -force
fi

# Start Hadoop
start-dfs.sh
start-yarn.sh

echo "Services started!"
echo "Hadoop web UI will be available at:"
echo "  http://localhost:9870"
echo "YARN web UI will be available at:"
echo "  http://localhost:8088"

# Keep container running
tail -f /dev/null
