# Objective 1: Cluster Architecture, Installation & Configuration (25%)

- [Objective 1: Cluster Architecture, Installation & Configuration (25%)](#objective-1-cluster-architecture-installation--configuration-25)
  - [Manage role based access control (RBAC)](#manage-role-based-access-control-rbac)
  - [Use Kubeadm to install a basic cluster](#use-kubeadm-to-install-a-basic-cluster)
  - [Manage a highly-available Kubernetes cluster](#manage-a-highly-available-kubernetes-cluster)
  - [Provision underlying infrastructure to deploy a Kubernetes cluster](#provision-underlying-infrastructure-to-deploy-a-kubernetes-cluster)
  - [Perform a version upgrade on a Kubernetes cluster using Kubeadm](#perform-a-version-upgrade-on-a-kubernetes-cluster-using-kubeadm)
  - [Implement etcd backup and restore](#implement-etcd-backup-and-restore)
    - [Snapshot the keyspace](#snapshot-the-keyspace)
    - [Restore from snapshot](#restore-from-snapshot)

## Manage role based access control (RBAC)

## Use Kubeadm to install a basic cluster

## Manage a highly-available Kubernetes cluster

## Provision underlying infrastructure to deploy a Kubernetes cluster

## Perform a version upgrade on a Kubernetes cluster using Kubeadm

## Implement etcd backup and restore

- [Operating etcd clusters for Kubernetes: Backing up an etcd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)
- [Etcd Documentation: Disaster Recovery](https://etcd.io/docs/v3.4.0/op-guide/recovery/)

### Snapshot the keyspace

**Command**:

`etcdctl snapshot save`

**Example**:

The following command snapshots the keyspace served by $ENDPOINT to the file snapshot.db:

`ETCDCTL_API=3 etcdctl --endpoints $ENDPOINT snapshot save snapshot.db`

### Restore from snapshot

Restoring overwrites some snapshot metadata (specifically, the member ID and cluster ID); the member loses its former identity.

Snapshot integrity is verified when restoring from a snapshot using an integrity hash created by `etcdctl snapshot save`, but not when restoring from a file copy.

**Command**:

`etcdctl snapshot restore`

**Example**:

The following creates new etcd data directories (m1.etcd, m2.etcd, m3.etcd) for a three member cluster:

```
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
