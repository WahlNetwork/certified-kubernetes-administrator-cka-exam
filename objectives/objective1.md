# Objective 1: Cluster Architecture, Installation & Configuration (25%)

- [Objective 1: Cluster Architecture, Installation & Configuration (25%)](#objective-1-cluster-architecture-installation--configuration-25)
  - [Manage role based access control (RBAC)](#manage-role-based-access-control-rbac)
  - [Use Kubeadm to install a basic cluster](#use-kubeadm-to-install-a-basic-cluster)
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

- [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

The essential steps are:

- Install Ubuntu 18.04 LTS on an instance with at least 2 vCPUs and 2 GiB of memory (e.g. `t3a.small`)
  - [Disable Swap](https://askubuntu.com/questions/214805/how-do-i-disable-swap) using the user data field for the instance(s)
- [Configure iptables](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#letting-iptables-see-bridged-traffic) to see bridged traffic
- [Install the Docker container runtime](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker)
- [Install kubeadm, kubelet, and kubectl](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl) on each node
- [kubeadm init](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node) on the control node
- [kubeadm join](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#join-nodes) on the worker node(s)
- Optionally, [taint the master](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) to accept pods

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
