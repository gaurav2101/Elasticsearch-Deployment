#### ElasticSearch Installation & Configuration ####
#!/bin/bash
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
sudo mv /tmp/elasticsearch.repo /etc/yum.repos.d/elasticsearch.repo
sudo yum install -y --enablerepo=elasticsearch elasticsearch
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service
sudo mkdir -p /mnt/elasticsearch/logs
sudo mkdir -p /mnt/elasticsearch/data
sudo mkdir /etc/elasticsearch/certs
sudo /usr/share/elasticsearch/bin/elasticsearch-certutil ca --out /etc/elasticsearch/certs/elastic-stack-ca.p12 --pass ""
sudo /usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca /etc/elasticsearch/certs/elastic-stack-ca.p12 --ca-pass "" --pass "" --out /etc/elasticsearch/certs/elastic-certificates.p12
sudo chown -R root:elasticsearch /etc/elasticsearch
sudo chown -R elasticsearch:elasticsearch /mnt/elasticsearch/
sudo chmod -R 777 /etc/elasticsearch/certs/

sudo bash -c 'cat > /etc/elasticsearch/elasticsearch.yml' << EOF
####Cluster Configuration####
cluster.name: testdemosinglenode
path.data: /mnt/elasticsearch/data
path.logs: /mnt/elasticsearch/logs
http.port: 9200
transport.tcp.port: 9300
discovery.zen.minimum_master_nodes: 1
network.host: $HOSTNAME
network.bind_host: $HOSTNAME
network.publish_host: $HOSTNAME
discovery.seed_hosts: ["$HOSTNAME"]
cluster.initial_master_nodes: ["$HOSTNAME"]
xpack.security.enabled: true
xpack.security.audit.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /etc/elasticsearch/certs/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /etc/elasticsearch/certs/elastic-certificates.p12
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.verification_mode: certificate
xpack.security.http.ssl.keystore.path: /etc/elasticsearch/certs/elastic-certificates.p12
xpack.security.http.ssl.truststore.path: /etc/elasticsearch/certs/elastic-certificates.p12
EOF