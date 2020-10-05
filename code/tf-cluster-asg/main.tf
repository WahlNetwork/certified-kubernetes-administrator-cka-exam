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
  user_data = filebase64("${path.module}/userdata")
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