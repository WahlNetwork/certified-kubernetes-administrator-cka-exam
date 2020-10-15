variable "node-count" {
  default     = 1
  description = "The quantity of EC2 instances to launch in the Auto Scaling group"
  type        = number
}

variable "instance-name" {
  description = "The name of the EC2 instance"
  type        = string
}

variable "asg-name" {
  description = "The name of the Auto Scaling group"
  type        = string
}

variable "keypair-name" {
  description = "The name of the EC2 key pair"
  type        = string
}

variable "tag-environment" {
  description = "Assigns and AWS environment tag to resources"
  type        = string
}

variable "security-group-name" {
  description = "The name of the VPC security group"
  type        = string
}

variable "subnet-name" {
  description = "The name of the VCP subnet"
  type        = string
}

variable "instance-type" {
  description = "The type of EC2 instance to deploy"
  type        = string
}
