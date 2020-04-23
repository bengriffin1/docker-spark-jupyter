FROM python:3.6-buster

# SET WORKDIR
WORKDIR /src

# INSTALL JAVA
RUN echo "deb http://ftp.us.debian.org/debian sid main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    rm -rf /var/cache/apt/*

# INSTALL MAVEN as EXCEPTED by GLUE
RUN apt-get install -y wget
RUN wget https://aws-glue-etl-artifacts.s3.amazonaws.com/glue-common/apache-maven-3.6.0-bin.tar.gz
RUN tar zxvf apache-maven-3.6.0-bin.tar.gz
ENV PATH=/src/apache-maven-3.6.0/bin:$PATH
RUN rm apache-maven-3.6.0-bin.tar.gz

# BUILD PATCHED HIVE FOR HIVE CLIENT
WORKDIR /src
RUN git clone https://github.com/apache/hive.git
WORKDIR /src/hive
RUN wget https://issues.apache.org/jira/secure/attachment/12958418/HIVE-12679.branch-2.3.patch
RUN git checkout branch-2.3
RUN patch -p0 <HIVE-12679.branch-2.3.patch
RUN mvn clean install -DskipTests

# GET THE AWS REPO AND CONFIGURE POM
WORKDIR /src
RUN git clone https://github.com/awslabs/aws-glue-data-catalog-client-for-apache-hive-metastore.git
WORKDIR /src/aws-glue-data-catalog-client-for-apache-hive-metastore
COPY pom.xml /src/aws-glue-data-catalog-client-for-apache-hive-metastore

# BUILD THE HIVE CLIENT
WORKDIR /src/aws-glue-data-catalog-client-for-apache-hive-metastore/aws-glue-datacatalog-hive2-client
RUN mvn clean install -DskipTests
