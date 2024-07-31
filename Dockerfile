FROM centos:7

COPY elasticsearch-7.17.22-linux-x86_64.tar.gz  /opt
COPY elasticsearch-7.17.22-linux-x86_64.tar.gz.sha512  /opt
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* &&\
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* &&\
    cd /opt && \
    groupadd elasticsearch && \
    useradd -c "elasticsearch" -g elasticsearch elasticsearch &&\
    yum update -y && yum -y install wget perl-Digest-SHA && \
    shasum -a 512 -c elasticsearch-7.17.22-linux-x86_64.tar.gz.sha512 && \
    tar -xzf elasticsearch-7.17.22-linux-x86_64.tar.gz && \
    rm elasticsearch-7.17.22-linux-x86_64.tar.gz elasticsearch-7.17.22-linux-x86_64.tar.gz.sha512 && \ 
    mkdir /var/lib/data && chmod -R 777 /var/lib/data && \
    chown -R elasticsearch:elasticsearch /opt/elasticsearch-7.17.22 && \
    yum -y remove wget perl-Digest-SHA && \
    yum clean all && \
    mkdir -p /var/lib/elasticsearch/logs &&\
    mkdir -p /var/lib/elasticsearch/data &&\
    chmod -R 777 /var/lib/elasticsearch/logs &&\
    chmod -R 777 /var/lib/elasticsearch/data &&\
    chgrp -R elasticsearch /var/lib/elasticsearch/logs &&\
    chgrp -R elasticsearch /var/lib/elasticsearch/data

COPY ./config/elasticsearch.yml /opt/elasticsearch-7.17.22/config/elasticsearch.yml

USER elasticsearch
WORKDIR /var/lib/elasticsearch/
EXPOSE 9200 9300
CMD ["/opt/elasticsearch-7.17.22/bin/elasticsearch"]