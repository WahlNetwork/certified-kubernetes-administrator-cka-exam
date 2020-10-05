# Provides the security group id value
data "aws_security_group" "sg" {
  tags = {
    Name = local.security-group-name
  }
}

# Provides the subnet id value
data "aws_subnet" "subnet" {
  tags = {
    Name = local.subnet-name
  }
}

# Provides an AWS Launch Template for constructing EC2 instances
resource "aws_launch_template" "cka-node" {
  name                   = local.instance-name
  image_id               = local.ami-id
  instance_type          = local.instance-type
  key_name               = local.keypair-name
  vpc_security_group_ids = [data.aws_security_group.sg.id]
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8
      encrypted   = "true"
    }
  }
  tags = {
    environment = local.tag-environment
    source      = "Terraform"
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = local.instance-name
      environment = local.tag-environment
      source      = "Terraform"
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = local.instance-name
      environment = local.tag-environment
      source      = "Terraform"
    }
  }
  user_data = "IyEvYmluL2Jhc2gKCiMgRGlzYWJsZSBTd2FwCnN1ZG8gc3dhcG9mZiAtYQoKIyBCcmlkZ2UgTmV0d29yawpzdWRvIG1vZHByb2JlIGJyX25ldGZpbHRlcgpzdWRvIGNhdCA8PCdFT0YnIHwgc3VkbyB0ZWUgL2V0Yy9zeXNjdGwuZC9rOHMuY29uZgpuZXQuYnJpZGdlLmJyaWRnZS1uZi1jYWxsLWlwNnRhYmxlcyA9IDEKbmV0LmJyaWRnZS5icmlkZ2UtbmYtY2FsbC1pcHRhYmxlcyA9IDEKRU9GCnN1ZG8gc3lzY3RsIC0tc3lzdGVtCgojIEluc3RhbGwgRG9ja2VyCnN1ZG8gY3VybCAtZnNTTCBodHRwczovL2dldC5kb2NrZXIuY29tIC1vIC9ob21lL3VidW50dS9nZXQtZG9ja2VyLnNoCnN1ZG8gc2ggL2hvbWUvdWJ1bnR1L2dldC1kb2NrZXIuc2gKCiMgSW5zdGFsbCBLdWJlIHRvb2xzCnN1ZG8gYXB0LWdldCB1cGRhdGUgJiYgc3VkbyBhcHQtZ2V0IGluc3RhbGwgLXkgYXB0LXRyYW5zcG9ydC1odHRwcyBjdXJsCmN1cmwgLXMgaHR0cHM6Ly9wYWNrYWdlcy5jbG91ZC5nb29nbGUuY29tL2FwdC9kb2MvYXB0LWtleS5ncGcgfCBzdWRvIGFwdC1rZXkgYWRkIC0KY2F0IDw8J0VPRicgfCBzdWRvIHRlZSAvZXRjL2FwdC9zb3VyY2VzLmxpc3QuZC9rdWJlcm5ldGVzLmxpc3QKZGViIGh0dHBzOi8vYXB0Lmt1YmVybmV0ZXMuaW8vIGt1YmVybmV0ZXMteGVuaWFsIG1haW4KRU9GCnN1ZG8gYXB0LWdldCB1cGRhdGUKc3VkbyBhcHQtZ2V0IGluc3RhbGwgLXkga3ViZWxldCBrdWJlYWRtIGt1YmVjdGwKc3VkbyBhcHQtbWFyayBob2xkIGt1YmVsZXQga3ViZWFkbSBrdWJlY3Rs"
}

# Provides an Auto Scaling group using instances described in the Launch Template
resource "aws_autoscaling_group" "cka-cluster-1" {
  desired_capacity    = local.node-count
  max_size            = local.node-count
  min_size            = local.node-count
  name                = local.asg-name
  vpc_zone_identifier = [data.aws_subnet.subnet.id]
  launch_template {
    id      = aws_launch_template.cka-node.id
    version = "$Latest"
  }
}