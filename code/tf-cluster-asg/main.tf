# Provides the security group id value
data "aws_security_group" "sg" {
  tags = {
    Name = var.security-group-name
  }
}

# Provides the subnet id value
data "aws_subnet" "subnet" {
  tags = {
    Name = var.subnet-name
  }
}

# Provides an AWS Launch Template for constructing EC2 instances
resource "aws_launch_template" "cka-node" {
  name                   = var.instance-name
  image_id               = "ami-07a29e5e945228fa1"
  instance_type          = var.instance-type
  key_name               = var.keypair-name
  vpc_security_group_ids = [data.aws_security_group.sg.id]
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8
      encrypted   = "true"
    }
  }
  tags = {
    environment = var.tag-environment
    source      = "Terraform"
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = var.instance-name
      environment = var.tag-environment
      source      = "Terraform"
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = var.instance-name
      environment = var.tag-environment
      source      = "Terraform"
    }
  }
  user_data = filebase64("user_data.sh")
}

# Provides an Auto Scaling group using instances described in the Launch Template
resource "aws_autoscaling_group" "cka-cluster" {
  desired_capacity    = var.node-count
  max_size            = var.node-count
  min_size            = var.node-count
  name                = var.asg-name
  vpc_zone_identifier = [data.aws_subnet.subnet.id]
  launch_template {
    id      = aws_launch_template.cka-node.id
    version = "$Latest"
  }
}
