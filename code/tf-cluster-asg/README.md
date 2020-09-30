# Terraform Plan to Create Auto Scaling Group

This plan will create the following resources:

- Launch Template with EC2 instances prepared to install Kubernetes with `kubeadm`
- Auto Scaling group to deploy as many instances as your heart desires

## Todo Items

- Refactor the Terraform code to accept variables instead of using local inputs
- Add variable for the Provider to select the AWS region of choice
