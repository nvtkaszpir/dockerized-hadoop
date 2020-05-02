FROM openjdk:8-jre-slim

LABEL maintainer="cgiraldo@gradiant.org" \
      organization="gradiant.org"

ARG HADOOP_VERSION=3.1.3
ENV HADOOP_VERSION=$HADOOP_VERSION \
    HADOOP_PREFIX=/opt/hadoop \
    HADOOP_HOME=/opt/hadoop \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    PATH=$PATH:/opt/hadoop/bin \
    MULTIHOMED_NETWORK=1 \
    CLUSTER_NAME=hadoop \
    HDFS_CONF_dfs_namenode_name_dir=file:///dfs/name \
    HDFS_CONF_dfs_datanode_data_dir=file:///dfs/data \
    USER=hdfs

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y curl procps sed && \
    rm -rf /var/lib/apt/lists/* && \
    curl -SL "https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" | tar xvz -C /opt && \
    ln -s "/opt/hadoop-$HADOOP_VERSION" /opt/hadoop && \
    # remove documentation from container image
    rm -r /opt/hadoop/share/doc && \
    if [ ! -f "$HADOOP_CONF_DIR/mapred-site.xml" ]; then \
        cp "$HADOOP_CONF_DIR/mapred-site.xml.template" "$HADOOP_CONF_DIR/mapred-site.xml"; \
    fi && \
    groupadd -g 114 -r hadoop && \
    useradd --comment "Hadoop HDFS" -u 201 --shell /bin/bash -M -r --groups hadoop --home /var/lib/hadoop/hdfs hdfs && \
    mkdir -p /dfs && \
    mkdir -p /opt/hadoop/logs && \
    chown -R hdfs:hadoop /dfs && \
    chown -LR hdfs:hadoop /opt/hadoop && \
    # fix dns issues with java, especially with short living containers
    # 30s is generally recommended, lower values will just stress dns more, while higher values
    # just tend to keep stale entries for too long
    sed -i 's/.*networkaddress.cache.ttl.*/networkaddress.cache.ttl=30/g' /usr/local/openjdk-8/lib/security/java.security
    # networkaddress.cache.negative.ttl=10 which is default



COPY entrypoint.sh /entrypoint.sh

USER hdfs
WORKDIR /opt/hadoop

VOLUME /dfs

EXPOSE 8020 

# HDFS 2.x web interface
EXPOSE 50070

# HDFS 3.x web interface
EXPOSE 9870

ENTRYPOINT ["/entrypoint.sh"]
