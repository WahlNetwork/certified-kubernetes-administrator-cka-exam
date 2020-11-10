# Objective 5: Troubleshooting

- [Troubleshooting Kubernetes deployments](https://learnk8s.io/troubleshooting-deployments)

- [Objective 5: Troubleshooting](#objective-5-troubleshooting)
  - [5.1 Evaluate Cluster And Node Logging](#51-evaluate-cluster-and-node-logging)
    - [Cluster Logging](#cluster-logging)
    - [Node Logging](#node-logging)
  - [5.2 Understand How To Monitor Applications](#52-understand-how-to-monitor-applications)
  - [5.3 Manage Container Stdout & Stderr Logs](#53-manage-container-stdout--stderr-logs)
  - [5.4 Troubleshoot Application Failure](#54-troubleshoot-application-failure)
  - [5.5 Troubleshoot Cluster Component Failure](#55-troubleshoot-cluster-component-failure)
  - [5.6 Troubleshoot Networking](#56-troubleshoot-networking)

## 5.1 Evaluate Cluster And Node Logging

### Cluster Logging

Having a separate storage location for cluster component logging, such as nodes, pods, and applications.

- [Cluster-level logging architectures](https://kubernetes.io/docs/concepts/cluster-administration/logging/#cluster-level-logging-architectures)
- [Kubernetes Logging Best Practices](https://platform9.com/blog/kubernetes-logging-best-practices/)

Commonly deployed in one of three ways:

1. [Logging agent on each node](https://kubernetes.io/docs/concepts/cluster-administration/logging/#using-a-node-logging-agent) that sends log data to a backend storage repository
   1. These agents can be deployed using a DaemonSet replica to ensure nodes have the agent running
   2. Note: This approach only works for applications' standard output (_stdout_) and standard error (_stderr_)
2. [Logging agent as a sidecar](https://kubernetes.io/docs/concepts/cluster-administration/logging/#using-a-sidecar-container-with-the-logging-agent) to specific deployments that sends log data to a backend storage repository
   1. Note: Writing logs to a file and then streaming them to stdout can double disk usage
3. [Configure the containerized application](https://kubernetes.io/docs/concepts/cluster-administration/logging/#exposing-logs-directly-from-the-application) to send log data to a backend storage repository

### Node Logging

Having a log file on the node that is populated with standard output (_stdout_) and standard error (_stderr_) log entries from containers running on the node.

- [Logging at the node level](https://kubernetes.io/docs/concepts/cluster-administration/logging/#logging-at-the-node-level)

## 5.2 Understand How To Monitor Applications

- [Using kubectl describe pod to fetch details about pods](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application-introspection/#using-kubectl-describe-pod-to-fetch-details-about-pods)
- [Interacting with running Pods](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#interacting-with-running-pods)

## 5.3 Manage Container Stdout & Stderr Logs

- [Kubectl Commands - Logs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs)
- [How to find—and use—your GKE logs with Cloud Logging](https://cloud.google.com/blog/products/management-tools/finding-your-gke-logs)
- [Enable Log Rotation in Kubernetes Cluster](https://vividcode.io/enable-log-rotation-in-kubernetes-cluster/)

`kubectl logs [-f] [-p] (POD | TYPE/NAME) [-c CONTAINER]`

- `-f` will follow the logs
- `-p` will pull up the previous instance of the container
- `-c` will select a specific container for pods that have more than one

## 5.4 Troubleshoot Application Failure

- [Troubleshoot Applications](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application/)
- Status: Pending
  - The Pod has been accepted by the Kubernetes cluster, but one or more of the containers has not been set up and made ready to run.
  - If no resources available on cluster, Cluster Autoscaling will increased node count if enabled
  - Once node count satisfied, pods in Pending status will be deployed
- Status: Waiting
  - A container in the Waiting state is still running the operations it requires in order to complete start up

---

Describe the pod to get details on the configuration, containers, events, conditions, volumes, etc.

- Is the status equal to RUNNING?
- Are there enough resources to schedule the pod?
- Are there enough `hostPorts` remaining to schedule the pod?

`kubectl describe pod counter`

```yaml
Name:         counter
Namespace:    default
Priority:     0
Node:         gke-my-first-cluster-1-default-pool-504c1e77-xcvj/10.128.0.15
Start Time:   Tue, 10 Nov 2020 16:33:10 -0600
Labels:       <none>
Annotations:  <none>
Status:       Running
IP:           10.104.1.7
IPs:
  IP:  10.104.1.7
Containers:
  count:
    Container ID:  docker://430313804a529153c1dc5badd1394164906a7dead8708a4b850a0466997e1c34
    Image:         busybox
    Image ID:      docker-pullable://busybox@sha256:a9286defaba7b3a519d585ba0e37d0b2cbee74ebfe590960b0b1d6a5e97d1e1d
    Port:          <none>
    Host Port:     <none>
    Args:
      /bin/sh
      -c
      i=0; while true; do
        echo "$i: $(date)" >> /var/log/1.log;
        echo "$(date) INFO $i" >> /var/log/2.log;
        i=$((i+1));
        sleep 1;
      done

    State:          Running
      Started:      Tue, 10 Nov 2020 16:33:12 -0600
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/log from varlog (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-2qnnp (ro)
  count-log-1:
    Container ID:  docker://d5e95aa4aec3a55435d610298f94e7b8b2cfdf2fb88968f00ca4719a567a6e37
    Image:         busybox
    Image ID:      docker-pullable://busybox@sha256:a9286defaba7b3a519d585ba0e37d0b2cbee74ebfe590960b0b1d6a5e97d1e1d
    Port:          <none>
    Host Port:     <none>
    Args:
      /bin/sh
      -c
      tail -n+1 -f /var/log/1.log
    State:          Running
      Started:      Tue, 10 Nov 2020 16:33:13 -0600
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/log from varlog (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-2qnnp (ro)
  count-log-2:
    Container ID:  docker://eaa9983cbd55288a139b63c30cfe3811031dedfae0842b9233ac48db65387d4d
    Image:         busybox
    Image ID:      docker-pullable://busybox@sha256:a9286defaba7b3a519d585ba0e37d0b2cbee74ebfe590960b0b1d6a5e97d1e1d
    Port:          <none>
    Host Port:     <none>
    Args:
      /bin/sh
      -c
      tail -n+1 -f /var/log/2.log
    State:          Running
      Started:      Tue, 10 Nov 2020 16:33:13 -0600
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/log from varlog (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-2qnnp (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  varlog:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:
    SizeLimit:  <unset>
  default-token-2qnnp:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-2qnnp
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                 node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From                                                        Message
  ----    ------     ----  ----                                                        -------
  Normal  Scheduled  30m   default-scheduler                                           Successfully assigned default/counter to gke-my-first-cluster-1-default-pool-504c1e77-xcvj
  Normal  Pulling    30m   kubelet, gke-my-first-cluster-1-default-pool-504c1e77-xcvj  Pulling image "busybox"
  Normal  Pulled     30m   kubelet, gke-my-first-cluster-1-default-pool-504c1e77-xcvj  Successfully pulled image "busybox"
  Normal  Created    30m   kubelet, gke-my-first-cluster-1-default-pool-504c1e77-xcvj  Created container count
  Normal  Started    30m   kubelet, gke-my-first-cluster-1-default-pool-504c1e77-xcvj  Started container count
  Normal  Pulling    30m   kubelet, gke-my-first-cluster-1-default-pool-504c1e77-xcvj  Pulling image "busybox"
  Normal  Created    30m   kubelet, gke-my-first-cluster-1-default-pool-504c1e77-xcvj  Created container count-log-1
  Normal  Pulled     30m   kubelet, gke-my-first-cluster-1-default-pool-504c1e77-xcvj  Successfully pulled image "busybox"
  Normal  Started    30m   kubelet, gke-my-first-cluster-1-default-pool-504c1e77-xcvj  Started container count-log-1
  Normal  Pulling    30m   kubelet, gke-my-first-cluster-1-default-pool-504c1e77-xcvj  Pulling image "busybox"
  Normal  Pulled     30m   kubelet, gke-my-first-cluster-1-default-pool-504c1e77-xcvj  Successfully pulled image "busybox"
  Normal  Created    30m   kubelet, gke-my-first-cluster-1-default-pool-504c1e77-xcvj  Created container count-log-2
  Normal  Started    30m   kubelet, gke-my-first-cluster-1-default-pool-504c1e77-xcvj  Started container count-log-2
```

---

Validate the commands being presented to the pod to ensure nothing was configured incorrectly.

`kubectl apply --validate -f mypod.yaml`

## 5.5 Troubleshoot Cluster Component Failure

- [Troubleshoot Clusters](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/)
- [A general overview of cluster failure modes](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/#a-general-overview-of-cluster-failure-modes)
- [Control Plane Components](https://kubernetes.io/docs/concepts/overview/components/#control-plane-components)
- [Node Components](https://kubernetes.io/docs/concepts/overview/components/#node-components)

---

Components to investigate:

- Control Plane Components
  - `kube-apiserver`
  - `etcd`
  - `kube-scheduler`
  - `kube-controller-manager`
  - `cloud-controller-manager`
- Node Components
  - `kubelet`
  - `kube-proxy`
  - Container runtime (e.g. Docker)

---

View the components with:

`kubectl get all -n kube-system`

```bash
NAME                                                               READY   STATUS    RESTARTS   AGE
pod/konnectivity-agent-56nck                                       1/1     Running   0          15d
pod/konnectivity-agent-gmklx                                       1/1     Running   0          15d
pod/konnectivity-agent-wg92c                                       1/1     Running   0          15d
pod/kube-dns-576766df6b-cz4ln                                      3/3     Running   0          15d
pod/kube-dns-576766df6b-rcsk7                                      3/3     Running   0          15d
pod/kube-dns-autoscaler-7f89fb6b79-pq66d                           1/1     Running   0          15d
pod/kube-proxy-gke-my-first-cluster-1-default-pool-504c1e77-m9lk   1/1     Running   0          15d
pod/kube-proxy-gke-my-first-cluster-1-default-pool-504c1e77-xcvj   1/1     Running   0          15d
pod/kube-proxy-gke-my-first-cluster-1-default-pool-504c1e77-zg6v   1/1     Running   0          15d
pod/l7-default-backend-7fd66b8b88-ng57f                            1/1     Running   0          15d
pod/metrics-server-v0.3.6-7c5cb99b6f-2d8bx                         2/2     Running   0          15d

NAME                           TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
service/default-http-backend   NodePort    10.108.1.184   <none>        80:32084/TCP    15d
service/kube-dns               ClusterIP   10.108.0.10    <none>        53/UDP,53/TCP   15d
service/metrics-server         ClusterIP   10.108.1.154   <none>        443/TCP         15d

NAME                                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                                        AGE
daemonset.apps/konnectivity-agent         3         3         3       3            3           <none>                                                               15d
daemonset.apps/kube-proxy                 0         0         0       0            0           kubernetes.io/os=linux,node.kubernetes.io/kube-proxy-ds-ready=true   15d
daemonset.apps/metadata-proxy-v0.1        0         0         0       0            0           cloud.google.com/metadata-proxy-ready=true,kubernetes.io/os=linux    15d
daemonset.apps/nvidia-gpu-device-plugin   0         0         0       0            0           <none>                                                               15d

NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kube-dns                2/2     2            2           15d
deployment.apps/kube-dns-autoscaler     1/1     1            1           15d
deployment.apps/l7-default-backend      1/1     1            1           15d
deployment.apps/metrics-server-v0.3.6   1/1     1            1           15d

NAME                                               DESIRED   CURRENT   READY   AGE
replicaset.apps/kube-dns-576766df6b                2         2         2       15d
replicaset.apps/kube-dns-autoscaler-7f89fb6b79     1         1         1       15d
replicaset.apps/l7-default-backend-7fd66b8b88      1         1         1       15d
replicaset.apps/metrics-server-v0.3.6-7c5cb99b6f   1         1         1       15d
replicaset.apps/metrics-server-v0.3.6-7ff8cdbc49   0         0         0       15d
```

---

Retrieve detailed information about the cluster

`kubectl cluster-info` or `kubectl cluster-info dump`

---

Retrieve a list of known API resources to aid with describing or troubleshooting

`kubectl api-resources`

```bash
NAME                              SHORTNAMES   APIGROUP                       NAMESPACED   KIND
bindings                                                                      true         Binding
componentstatuses                 cs                                          false        ComponentStatus
configmaps                        cm                                          true         ConfigMap
endpoints                         ep                                          true         Endpoints
events                            ev                                          true         Event
limitranges                       limits                                      true         LimitRange
namespaces                        ns                                          false        Namespace
nodes                             no                                          false        Node
persistentvolumeclaims            pvc                                         true         PersistentVolumeClaim
persistentvolumes                 pv                                          false        PersistentVolume

<snip>
```

---

[Check the logs](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/#looking-at-logs) in `/var/log` on the master and worker nodes:

- Master
  - `/var/log/kube-apiserver.log` - API Server, responsible for serving the API
  - `/var/log/kube-scheduler.log` - Scheduler, responsible for making scheduling decisions
  - `/var/log/kube-controller-manager.log` - Controller that manages replication controllers
- Worker Nodes
  - `/var/log/kubelet.log` - Kubelet, responsible for running containers on the node
  - `/var/log/kube-proxy.log` - Kube Proxy, responsible for service load balancing

## 5.6 Troubleshoot Networking

- [Flannel Troubleshooting](https://github.com/coreos/flannel/blob/master/Documentation/troubleshooting.md#kubernetes-specific)
  - The flannel kube subnet manager relies on the fact that each node already has a podCIDR defined.
- [Calico Troubleshooting](https://docs.projectcalico.org/maintenance/troubleshoot/)
  - [Containers do not have network connectivity](https://docs.projectcalico.org/maintenance/troubleshoot/troubleshooting#containers-do-not-have-network-connectivity)
