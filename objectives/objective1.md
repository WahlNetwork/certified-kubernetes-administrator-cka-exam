# Objective 1: Cluster Architecture, Installation & Configuration

- [Objective 1: Cluster Architecture, Installation & Configuration](#objective-1-cluster-architecture-installation--configuration)
  - [1.1 Manage Role Based Access Control (RBAC)](#11-manage-role-based-access-control-rbac)
    - [Lab Environment](#lab-environment)
    - [Lab Practice](#lab-practice)
  - [1.2 Use Kubeadm to Install a Basic Cluster](#12-use-kubeadm-to-install-a-basic-cluster)
    - [Kubeadm Tasks for All Nodes](#kubeadm-tasks-for-all-nodes)
    - [Kubeadm Tasks for Single Control Node](#kubeadm-tasks-for-single-control-node)
    - [Kubeadm Tasks for Worker Node(s)](#kubeadm-tasks-for-worker-nodes)
    - [Kubeadm Troubleshooting](#kubeadm-troubleshooting)
    - [Kubeadm Optional Tasks](#kubeadm-optional-tasks)
  - [1.3 Manage A Highly-Available Kubernetes Cluster](#13-manage-a-highly-available-kubernetes-cluster)
    - [HA Deployment Types](#ha-deployment-types)
    - [Upgrading from Single Control-Plane to High Availability](#upgrading-from-single-control-plane-to-high-availability)
  - [1.4 Provision Underlying Infrastructure to Deploy a Kubernetes Cluster](#14-provision-underlying-infrastructure-to-deploy-a-kubernetes-cluster)
  - [1.5 Perform a Version Upgrade on a Kubernetes Cluster using Kubeadm](#15-perform-a-version-upgrade-on-a-kubernetes-cluster-using-kubeadm)
    - [First Control Plane Node](#first-control-plane-node)
    - [Additional Control Plane Nodes](#additional-control-plane-nodes)
    - [Upgrade Control Plane Node Kubectl And Kubelet Tools](#upgrade-control-plane-node-kubectl-and-kubelet-tools)
    - [Upgrade Worker Nodes](#upgrade-worker-nodes)
  - [1.6 Implement Etcd Backup And Restore](#16-implement-etcd-backup-and-restore)
    - [Snapshot The Keyspace](#snapshot-the-keyspace)
    - [Restore From Snapshot](#restore-from-snapshot)

## 1.1 Manage Role Based Access Control (RBAC)

Documentation and Resources:

- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [A Practical Approach to Understanding Kubernetes Authorization](https://thenewstack.io/a-practical-approach-to-understanding-kubernetes-authorization/)

RBAC is handled by roles (permissions) and bindings (assignment of permissions to subjects):

| Object               | Description                                                                                  |
| -------------------- | -------------------------------------------------------------------------------------------- |
| `Role`               | Permissions within a particular namespace                                                    |
| `ClusterRole`        | Permissions to non-namespaced resources; can be used to grant the same permissions as a Role |
| `RoleBinding`        | Grants the permissions defined in a role to a user or set of users                           |
| `ClusterRoleBinding` | Grant permissions across a whole cluster                                                     |

### Lab Environment

If desired, use a managed Kubernetes cluster, such as Amazon EKS, to immediately begin working with RBAC. The command `aws --region REGION eks update-kubeconfig --name CLUSTERNAME` will generate a .kube configuration file on your workstation to permit kubectl commands.

### Lab Practice

Create the `wahlnetwork1` namespace.

`kubectl create namespace wahlnetwork1`

---

Create a deployment in the `wahlnetwork1` namespace using the image of your choice:

1. `kubectl create deployment hello-node --image=k8s.gcr.io/echoserver:1.4 -n wahlnetwork1`
1. `kubectl create deployment busybox --image=busybox -n wahlnetwork1 -- sleep 2000`

You can view the yaml file by adding `--dry-run=client -o yaml` to the end of either deployment.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: hello-node
  name: hello-node
  namespace: wahlnetwork1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-node
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: hello-node
    spec:
      containers:
        - image: k8s.gcr.io/echoserver:1.4
          name: echoserver
          resources: {}
```

---

Create the `pod-reader` role in the `wahlnetwork1` namespace.

`kubectl create role pod-reader --verb=get --verb=list --verb=watch --resource=pods -n wahlnetwork1`

> Alternatively, use `kubectl create role pod-reader --verb=get --verb=list --verb=watch --resource=pods -n wahlnetwork1 --dry-run=client -o yaml` to output a proper yaml configuration.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: null
  name: pod-reader
  namespace: wahlnetwork1
rules:
  - apiGroups:
      - ""
    resources:
      - pods
    verbs:
      - get
      - list
      - watch
```

---

Create the `read-pods` rolebinding between the role named `pod-reader` and the user `spongebob` in the `wahlnetwork1` namespace.

`kubectl create rolebinding --role=pod-reader --user=spongebob read-pods -n wahlnetwork1`

> Alternatively, use `kubectl create rolebinding --role=pod-reader --user=spongebob read-pods -n wahlnetwork1 --dry-run=client -o yaml` to output a proper yaml configuration.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: null
  name: read-pods
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: spongebob
```

---

Create the `cluster-secrets-reader` clusterrole.

`kubectl create clusterrole cluster-secrets-reader --verb=get --verb=list --verb=watch --resource=secrets`

> Alternatively, use `kubectl create clusterrole cluster-secrets-reader --verb=get --verb=list --verb=watch --resource=secrets --dry-run=client -o yaml` to output a proper yaml configuration.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: cluster-secrets-reader
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
  - list
  - watch
```

---

Create the `cluster-read-secrets` clusterrolebinding between the clusterrole named `cluster-secrets-reader` and the user `gizmo`.

`kubectl create clusterrolebinding --clusterrole=cluster-secrets-reader --user=gizmo cluster-read-secrets`

> Alternatively, use `kubectl create clusterrolebinding --clusterrole=cluster-secrets-reader --user=gizmo cluster-read-secrets --dry-run=client -o yaml` to output a proper yaml configuration.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: null
  name: cluster-read-secrets
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-secrets-reader
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: gizmo
```

Test to see if this works by running the `auth` command.

`kubectl auth can-i get secrets --as=gizmo`

Attempt to get secrets as the `gizmo` user.

`kubectl get secrets --as=gizmo`

```bash
NAME                  TYPE                                  DATA   AGE
default-token-lz87v   kubernetes.io/service-account-token   3      7d1h
```

## 1.2 Use Kubeadm to Install a Basic Cluster

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

Optionally, add `sudo kubeadm config images pull` to the end of the script to pre-pull images required for setting up a Kubernetes cluster.

```bash
$ sudo kubeadm config images pull

[config/images] Pulled k8s.gcr.io/kube-apiserver:v1.19.2
[config/images] Pulled k8s.gcr.io/kube-controller-manager:v1.19.2
[config/images] Pulled k8s.gcr.io/kube-scheduler:v1.19.2
[config/images] Pulled k8s.gcr.io/kube-proxy:v1.19.2
[config/images] Pulled k8s.gcr.io/pause:3.2
[config/images] Pulled k8s.gcr.io/etcd:3.4.13-0
[config/images] Pulled k8s.gcr.io/coredns:1.7.0
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

Alternatively, use the [Flannel CNI](https://coreos.com/flannel/docs/latest/kubernetes.html).

- Run `sudo kubeadm init --pod-network-cidr=10.244.0.0/16` to initialize the cluster and provide a pod network aligned to [Flannel's default configuration](https://github.com/coreos/flannel/blob/master/Documentation/kubernetes.md).
  - Note: The [`kube-flannel.yml`](https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml) file is hosted in the same location.

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

## 1.3 Manage A Highly-Available Kubernetes Cluster

[High Availability Production Environment](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)

Kubernetes Components for HA:

- Load Balancer / VIP
- DNS records
- etcd Endpoint
- Certificates
- Any HA specific queries / configuration / settings

### HA Deployment Types

- With stacked control plane nodes. This approach requires less infrastructure. The etcd members and control plane nodes are co-located.
- With an external etcd cluster. This approach requires more infrastructure. The control plane nodes and etcd members are separated. ([source](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/))

### Upgrading from Single Control-Plane to High Availability

If you have plans to upgrade this single control-plane kubeadm cluster to high availability you should specify the --control-plane-endpoint to set the shared endpoint for all control-plane nodes. Such an endpoint can be either a DNS name or an IP address of a load-balancer. ([source](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node))

## 1.4 Provision Underlying Infrastructure to Deploy a Kubernetes Cluster

See Objective [1.2 Use Kubeadm to Install a Basic Cluster](#12-use-kubeadm-to-install-a-basic-cluster).

> Note: Make sure that swap is disabled on all nodes.

## 1.5 Perform a Version Upgrade on a Kubernetes Cluster using Kubeadm

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

### Upgrade Control Plane Node Kubectl And Kubelet Tools

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

## 1.6 Implement Etcd Backup And Restore

- [Operating etcd clusters for Kubernetes: Backing up an etcd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)
- [Etcd Documentation: Disaster Recovery](https://etcd.io/docs/v3.4.0/op-guide/recovery/)
- [Kubernetes Tips: Backup and Restore Etcd](https://medium.com/better-programming/kubernetes-tips-backup-and-restore-etcd-97fe12e56c57)

### Snapshot The Keyspace

Use `etcdctl snapshot save`.

Snapshot the keyspace served by \$ENDPOINT to the file snapshot.db:

`ETCDCTL_API=3 etcdctl --endpoints $ENDPOINT snapshot save snapshot.db`

### Restore From Snapshot

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
