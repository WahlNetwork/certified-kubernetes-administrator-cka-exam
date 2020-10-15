# Terraform Plan to Create Auto Scaling Group

This plan will create the following resources:

- Launch Template with EC2 instances prepared to install Kubernetes with `kubeadm`
- Auto Scaling group to deploy as many instances as your heart desires

## Instructions

- Edit `local.tf` with your environment's information.
  - Optionally, edit `user_data.sh` if you wish to alter the startup script.
- Run `terraform init` and `terraform validate` to ensure the code is loaded properly.
- Run `terraform plan` to see the results of a plan against your environment.
- When satisfied, run `terraform apply` to apply the plan and construct the Launch Template and Auto Scaling group.
- If more/less nodes are needed:
  - Edit `local.tf` and modify the `node-count` value to the desired amount.
  - Re-run `terraform apply` and the Auto Scaling group will create/destroy nodes to reach the new value.
- When done, use `terraform destroy` to remove all resources and terminate potential billing.
