data "aws_ami" "elasticami" {
  owners = [ "self" ]
  most_recent = true
  filter {
      name = "name"
      values = ["elastic-base-ami-*"]
  }
  filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }
  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  } 
}

data "aws_iam_policy" "SSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_instance" "elastic_instance" {
  ami = data.aws_ami.elasticami.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.esclustersg.name]
  iam_instance_profile = aws_iam_instance_profile.elasticsearch-profile.name
  monitoring = true
  tags = {
    "Name" = "Elasticsearch-Instance",
    "Region" = var.region
  }
  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }
  user_data = <<-EOF
              #!/bin/bash
              sed -i '/network.host/c\network.host: '"$HOSTNAME"'' /etc/elasticsearch/elasticsearch.yml
              sed -i '/network.bind_host/c\network.bind_host: '"$HOSTNAME"'' /etc/elasticsearch/elasticsearch.yml
              sed -i '/network.publish_host/c\network.publish_host: '"$HOSTNAME"'' /etc/elasticsearch/elasticsearch.yml
              sed -i '/discovery.seed_hosts:/c\discovery.seed_hosts: '["'$HOSTNAME'"]'' /etc/elasticsearch/elasticsearch.yml
              sed -i '/cluster.initial_master_nodes/c\cluster.initial_master_nodes: '["'$HOSTNAME'"]'' /etc/elasticsearch/elasticsearch.yml
              sudo service elasticsearch      
              EOF
}

resource "aws_security_group" "esclustersg" {
  name = "elasticsearchcluster-sg"
  description = "Allow Intercluster Communication"
  ingress {
    description = "Enable cluster communication on port 9200"
    from_port = "9200"
    to_port = "9200"
    protocol = "tcp"
    self = true
  }
  ingress {
    description = "Enable cluster communication on port 9300"
    from_port = "9300"
    to_port = "9300"
    protocol = "tcp"
    self = true
  }
  egress {
    description = "Enable cluster communication on port 9200"
    from_port = "9200"
    to_port = "9200"
    protocol = "tcp"
    self = true        
  }
  egress {
    description = "Enable cluster communication on port 9300"
    from_port = "9300"
    to_port = "9300"
    protocol = "tcp"
    self = true
  }
  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Internet Communication"
    from_port = 0
    to_port = 0
    protocol = -1
  }
}

resource "aws_iam_instance_profile" "elasticsearch-profile" {
  name = "elasticsearch-profile"
  role = aws_iam_role.iam_role.name
}

resource "aws_iam_role" "iam_role" {
  name = "elasticsearch-role"
  path = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role = aws_iam_role.iam_role.name
  policy_arn = data.aws_iam_policy.SSMManagedInstanceCore.arn
}

resource "aws_cloudwatch_metric_alarm" "cpu-utilization" {
  alarm_name          = "Elasticsearch-CPU-Utilization-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.monitoring_notification.arn] 

  dimensions = {
    InstanceId = aws_instance.elastic_instance.id
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "Elasticsearch-Status-Check-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ec2 status check."
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.monitoring_notification.arn]

  dimensions = {
    InstanceId = aws_instance.elastic_instance.id
  }
}

resource "aws_sns_topic" "monitoring_notification" {
  name = "elasticsearch-cluster-snstopic" 
}