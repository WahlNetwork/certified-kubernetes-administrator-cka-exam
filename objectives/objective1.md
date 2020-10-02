# Objective 1: Cluster Architecture, Installation & Configuration

> ⚠ This section is not complete ⚠

- [Objective 1: Cluster Architecture, Installation & Configuration](#objective-1-cluster-architecture-installation--configuration)
  - [Manage role based access control (RBAC)](#manage-role-based-access-control-rbac)
  - [Use Kubeadm to install a basic cluster](#use-kubeadm-to-install-a-basic-cluster)
    - [Kubeadm Tasks for All Nodes](#kubeadm-tasks-for-all-nodes)
    - [Kubeadm Tasks for Single Control Node](#kubeadm-tasks-for-single-control-node)
    - [Kubeadm Tasks for Worker Node(s)](#kubeadm-tasks-for-worker-nodes)
    - [Kubeadm Troubleshooting](#kubeadm-troubleshooting)
    - [Kubeadm Optional Tasks](#kubeadm-optional-tasks)
  - [Manage a highly-available Kubernetes cluster](#manage-a-highly-available-kubernetes-cluster)
  - [Provision underlying infrastructure to deploy a Kubernetes cluster](#provision-underlying-infrastructure-to-deploy-a-kubernetes-cluster)
  - [Perform a version upgrade on a Kubernetes cluster using Kubeadm](#perform-a-version-upgrade-on-a-kubernetes-cluster-using-kubeadm)
    - [First Control Plane Node](#first-control-plane-node)
    - [Additional Control Plane Nodes](#additional-control-plane-nodes)
    - [Upgrade Control Plane Node kubectl and kubelet tools](#upgrade-control-plane-node-kubectl-and-kubelet-tools)
    - [Upgrade Worker Nodes](#upgrade-worker-nodes)
  - [Implement etcd backup and restore](#implement-etcd-backup-and-restore)
    - [Snapshot the keyspace](#snapshot-the-keyspace)
    - [Restore from snapshot](#restore-from-snapshot)

## Manage role based access control (RBAC)

## Use Kubeadm to install a basic cluster

Official documentation: [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

> Terraform code is available [here](../code/tf-cluster-asg/) to create the resources necessary to experiment with `kubeadm`

### Kubeadm Tasks for All Nodes

- Create Amazon EC2 Instances
  - Create an AWS Launch Template using an Ubuntu 18.04 LTS image (or newer) of size `t3a.small` (2 CPU, 2 GiB Memory).
  - Disable the [swap](https://askubuntu.com/questions/214805/how-do-i-disable-swap) file.
    - Note: This can be validated by using the console command `free` when SSH'd to the instance. The swap space total should be 0.
  - Consume this template as part of an Auto Scaling Group of 1 or more instances. This makes deployment of new instances and removal of old instances trivial.
- [Configure iptables](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#letting-iptables-see-bridged-traffic)
  - This allows iptables to see bridged traffic.
- [Install the Docker container runtime](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker)
  - The [docker-install](https://github.com/docker/docker-install) script is handy for this.
- [Install kubeadm, kubelet, and kubectl](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl)

Alternatively, use a `user-data` bash script attached to the Launch Template:

```bash
#!/bin/bash

# Disable Swap
sudo swapoff -a

# Bridge Network
sudo modprobe br_netfilter
sudo cat <<'EOF' | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

# Install Docker
sudo curl -fsSL https://get.docker.com -o /home/ubuntu/get-docker.sh
sudo sh /home/ubuntu/get-docker.sh

# Install Kube tools
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<'EOF' | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### Kubeadm Tasks for Single Control Node

- Initialize the cluster
  - Choose your Container Network Interface (CNI) plugin. This guide uses [Calico's CNI](https://docs.projectcalico.org/about/about-calico).
  - Run `sudo kubeadm init --pod-network-cidr=192.168.0.0/16` to initialize the cluster and provide a pod network aligned to [Calico's default configuration](https://docs.projectcalico.org/getting-started/kubernetes/quickstart#create-a-single-host-kubernetes-cluster).
  - Write down the `kubeadm join` output to [join worker nodes](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#join-nodes) later in this guide.
    - Example `kubeadm join 10.0.0.100:6443 --token 12345678901234567890 --discovery-token-ca-cert-hash sha256:123456789012345678901234567890123456789012345678901234567890`
- [Install Calico](https://docs.projectcalico.org/getting-started/kubernetes/quickstart)
- [Configure local kubectl access](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#optional-controlling-your-cluster-from-machines-other-than-the-control-plane-node)
  - This step simply copies the `admin.conf` file into a location accessible for a regular user.

### Kubeadm Tasks for Worker Node(s)

- [Join the cluster](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#join-nodes)
  - Note: You can view the cluster config with `kubectl config view`. This includes the cluster server address (e.g. `server: https://10.0.0.100:6443`)

### Kubeadm Troubleshooting

- If using `kubeadm init` without a pod network CIDR the CoreDNS pods will remain [stuck in pending state](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/#coredns-or-kube-dns-is-stuck-in-the-pending-state)
- Broke cluster and want to start over? Use `kubeadm reset` and `rm -rf .kube` in the user home directory to remove the old config and avoid [TLS certificate errors](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/#tls-certificate-errors)
- If seeing `error: error loading config file "/etc/kubernetes/admin.conf": open /etc/kubernetes/admin.conf: permission denied` it likely means the `KUBECONFIG` variable is set to that path, try `unset KUBECONFIG` to use the `$HOME/.kube/config` file.

### Kubeadm Optional Tasks

- [Install kubectl client locally on Windows](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-windows) for those using this OS.
- Single node cluster? [Taint the control node](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) to accept pods without dedicated worker nodes.
- Deploy the "hello-node" app from the [minikube tutorial](https://kubernetes.io/docs/tutorials/hello-minikube/) to test basic functionality.

## Manage a highly-available Kubernetes cluster

## Provision underlying infrastructure to deploy a Kubernetes cluster

## Perform a version upgrade on a Kubernetes cluster using Kubeadm

- [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [Safely Drain a Node while Respecting the PodDisruptionBudget](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
- [Cluster Management: Maintenance on a Node](https://kubernetes.io/docs/tasks/administer-cluster/cluster-management/#maintenance-on-a-node)

> Note: All containers are restarted after upgrade, because the container spec hash value is changed. Upgrades are constrained from one minor version to the next minor version.

### First Control Plane Node

Update the kubeadm tool and verify the new version

> Note: The `--allow-change-held-packages` flag is used because kubeadm updates should be held to prevent automated updates.

```bash
apt-get update && \
apt-get install -y --allow-change-held-packages kubeadm=1.19.x-00
kubeadm version
```

---

[Drain](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#drain) the node to mark as unschedulable

`kubectl drain $NODENAME --ignore-daemonsets`

<details><summary>Drain Diagram</summary>

![drain](https://kubernetes.io/images/docs/kubectl_drain.svg)

</details>

---

Perform an upgrade plan to validate that your cluster can be upgraded

> Note: This also fetches the versions you can upgrade to and shows a table with the component config version states.

`sudo kubeadm upgrade plan`

---

Upgrade the cluster

`sudo kubeadm upgrade apply v1.19.x`

---

[Uncordon](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#uncordon) the node to mark as schedulable

`kubectl uncordon $NODENAME`

### Additional Control Plane Nodes

Repeat the first control plane node steps while replacing the "upgrade the cluster" step using the command below:

`sudo kubeadm upgrade node`

### Upgrade Control Plane Node kubectl and kubelet tools

Upgrade the kubelet and kubectl on all control plane nodes

```bash
apt-get update && \
apt-get install -y --allow-change-held-packages kubelet=1.19.x-00 kubectl=1.19.x-00
```

---

Restart the kubelet

```bash
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### Upgrade Worker Nodes

Upgrade kubeadm

```bash
apt-get update && \
apt-get install -y --allow-change-held-packages kubeadm=1.19.x-00
```

---

Drain the node

`kubectl drain $NODENAME --ignore-daemonsets`

---

Upgrade the kubelet configuration

`sudo kubeadm upgrade node`

---

Upgrade kubelet and kubectl

```bash
apt-get update && \
apt-get install -y --allow-change-held-packages kubelet=1.19.x-00 kubectl=1.19.x-00

sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

---

Uncordon the node

`kubectl uncordon $NODENAME`

## Implement etcd backup and restore

- [Operating etcd clusters for Kubernetes: Backing up an etcd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)
- [Etcd Documentation: Disaster Recovery](https://etcd.io/docs/v3.4.0/op-guide/recovery/)
- [Kubernetes Tips: Backup and Restore Etcd](https://medium.com/better-programming/kubernetes-tips-backup-and-restore-etcd-97fe12e56c57)

### Snapshot the keyspace

Use `etcdctl snapshot save`.

Snapshot the keyspace served by \$ENDPOINT to the file snapshot.db:

`ETCDCTL_API=3 etcdctl --endpoints $ENDPOINT snapshot save snapshot.db`

### Restore from snapshot

Use `etcdctl snapshot restore`.

> Note: Restoring overwrites some snapshot metadata (specifically, the member ID and cluster ID); the member loses its former identity.
>
> Note: Snapshot integrity is verified when restoring from a snapshot using an integrity hash created by `etcdctl snapshot save`, but not when restoring from a file copy.

Create new etcd data directories (m1.etcd, m2.etcd, m3.etcd) for a three member cluster:

```bash
$ ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
  --name m1 \
  --initial-cluster m1=http://host1:2380,m2=http://host2:2380,m3=http://host3:2380 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-advertise-peer-urls http://host1:2380
$ ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
  --name m2 \
  --initial-cluster m1=http://host1:2380,m2=http://host2:2380,m3=http://host3:2380 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-advertise-peer-urls http://host2:2380
$ ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
  --name m3 \
  --initial-cluster m1=http://host1:2380,m2=http://host2:2380,m3=http://host3:2380 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-advertise-peer-urls http://host3:2380
```
