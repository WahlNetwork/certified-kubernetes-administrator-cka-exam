locals {
  node-count          = 2
  instance-name       = "cka-node"
  asg-name            = "cka-cluster-1"
  keypair-name        = "octo-kp-dev-usw2"
  tag-environment     = "dev"
  security-group-name = "open-octo-dev-usw2"
  subnet-name         = "private1-octo-dev-usw2"
  instance-type = "t3a.small"
}