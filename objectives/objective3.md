# Objective 3: Services & Networking

- [Objective 3: Services & Networking](#objective-3-services--networking)
  - [3.1 Understand Host Networking Configuration On The Cluster Nodes](#31-understand-host-networking-configuration-on-the-cluster-nodes)
  - [3.2 Understand Connectivity Between Pods](#32-understand-connectivity-between-pods)
  - [3.3 Understand ClusterIP, NodePort, LoadBalancer Service Types And Endpoints](#33-understand-clusterip-nodeport-loadbalancer-service-types-and-endpoints)
    - [ClusterIP](#clusterip)
    - [NodePort](#nodeport)
    - [LoadBalancer](#loadbalancer)
    - [ExternalIP](#externalip)
    - [ExternalName](#externalname)
    - [Networking Cleanup for Objective 3.3](#networking-cleanup-for-objective-33)
  - [3.4 Know How To Use Ingress Controllers And Ingress Resources](#34-know-how-to-use-ingress-controllers-and-ingress-resources)
  - [3.5 Know How To Configure And Use CoreDNS](#35-know-how-to-configure-and-use-coredns)
  - [3.6 Choose An Appropriate Container Network Interface Plugin](#36-choose-an-appropriate-container-network-interface-plugin)

> Note: If you need access to the pod network while working through the networking examples, use the [Get a Shell to a Running Container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/) guide to deploy a shell container. I often like to have a tab open to the shell container to run arbitrary network commands without the need to `exec` in and out of it repeatedly.

## 3.1 Understand Host Networking Configuration On The Cluster Nodes

- Design

  - All nodes can talk
  - All pods can talk (without NAT)
  - Every pod gets a unique IP address

- Network Types

  - Pod Network
  - Node Network
  - Services Network
    - Rewrites egress traffic destined to a service network endpoint with a pod network IP address

- Proxy Modes
  - IPTables Mode
    - The standard mode
    - `kube-proxy` watches the Kubernetes control plane for the addition and removal of Service and Endpoint objects
    - For each Service, it installs iptables rules, which capture traffic to the Service's clusterIP and port, and redirect that traffic to one of the Service's backend sets.
    - For each Endpoint object, it installs iptables rules which select a backend Pod.
    - [Official Documentation](https://kubernetes.io/docs/concepts/services-networking/service/#proxy-mode-iptables)
    - [Kubernetes Networking Demystified: A Brief Guide](https://www.stackrox.com/post/2020/01/kubernetes-networking-demystified/)
  - IPVS Mode
    - Since 1.11
    - Linux IP Virtual Server (IPVS)
    - L4 load balancer

## 3.2 Understand Connectivity Between Pods

[Official Documentation](https://kubernetes.io/docs/concepts/cluster-administration/networking/)

Read [The Kubernetes network model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#the-kubernetes-network-model):

- Every pod gets its own address
- Fundamental requirements on any networking implementation
  - Pods on a node can communicate with all pods on all nodes without NAT
  - Agents on a node (e.g. system daemons, kubelet) can communicate with all pods on that node
  - Pods in the host network of a node can communicate with all pods on all nodes without NAT
- Kubernetes IP addresses exist at the Pod scope
  - Containers within a pod can communicate with one another over `localhost`
  - "IP-per-pod" model

## 3.3 Understand ClusterIP, NodePort, LoadBalancer Service Types And Endpoints

Services are all about abstracting away the details of which pods are running behind a particular network endpoint. For many applications, work must be processed by some other service. Using a service allows the application to "toss over" the work to Kubernetes, which then uses a selector to determine which pods are healthy and available to receive the work. The service abstracts numerous replica pods that are available to do work.

- [Official Documentation](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Katakoda Networking Introduction](https://www.katacoda.com/courses/kubernetes/networking-introduction)

> Note: This section was completed using a GKE cluster and may differ from what your cluster looks like.

### ClusterIP

- Exposes the Service on a cluster-internal IP.
- Choosing this value makes the Service only reachable from within the cluster.
- This is the default ServiceType.
- [Using Source IP](https://kubernetes.io/docs/tutorials/services/source-ip/)
- [Kubectl Expose Command Reference](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#expose)

The imperative option is to create a deployment and then expose the deployment. In this example, the deployment is exposed using a ClusterIP service that accepts traffic on port 80 and translates it to the pod using port 8080.

`kubectl create deployment funkyapp1 --image=k8s.gcr.io/echoserver:1.4`

`kubectl expose deployment funkyapp1 --name=funkyip --port=80 --target-port=8080 --type=ClusterIP`

> Note: The `--type=ClusterIP` parameter is optional when deploying a `ClusterIP` service since this is the default type.

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: funkyapp1 #Selector
  name: funkyip
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
  selector:
    app: funkyapp1
  type: ClusterIP #Note this!
```

Using `kubectl describe svc funkyip` shows more details:

```bash
Name:              funkyip
Namespace:         default
Labels:            app=funkyapp1
Annotations:       cloud.google.com/neg: {"ingress":true}
Selector:          app=funkyapp1
Type:              ClusterIP
IP:                10.108.3.156
Port:              <unset>  80/TCP
TargetPort:        8080/TCP
Endpoints:         10.104.2.7:8080
Session Affinity:  None
Events:            <none>
```

---

Check to make sure the `funkyip` service exists. This also shows the assigned service (cluster IP) address.

`kubectl get svc funkyip`

```bash
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
funkyip      ClusterIP   10.108.3.156   <none>        80/TCP    21m
```

---

From there, you can see the endpoint created to match any pod discovered using the `app: funkyapp1` label.

`kubectl get endpoints funkyip`

```bash
NAME         ENDPOINTS           AGE
funkyip      10.104.2.7:8080     21m
```

---

The endpoint matches the IP address of the matching pod.

`kubectl get pods -o wide`

```bash
NAME                         READY   STATUS    RESTARTS   AGE     IP            NODE                                                NOMINATED NODE   READINESS GATES
funkyapp1-7b478ccf9b-2vlc2   1/1     Running   0          21m     10.104.2.7    gke-my-first-cluster-1-default-pool-504c1e77-zg6v   <none>           <none>
shell-demo                   1/1     Running   0          3m12s   10.128.0.14   gke-my-first-cluster-1-default-pool-504c1e77-m9lk   <none>           <none>
```

---

The `.spec.ports.port` value defines the port used to access the service. The `.spec.ports.targetPort` value defines the port used to access the container's application.

`User -> Port -> Kubernetes Service -> Target Port -> Application`

This can be tested using `curl`:

```bash
export CLUSTER_IP=$(kubectl get services/funkyip -o go-template='{{(index .spec.clusterIP)}}')
echo CLUSTER_IP=$CLUSTER_IP
```

From there, use `curl $CLUSTER_IP:80` to hit the service `port`, which redirects to the `targetPort` of 8080.

`curl 10.108.3.156:80`

```bash
CLIENT VALUES:
client_address=10.128.0.14
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://10.108.3.156:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=10.108.3.156
user-agent=curl/7.64.0
BODY:
-no body in request-root
```

### NodePort

- Exposes the Service on each Node's IP at a static port (the NodePort).
- [Official Documentation](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport)

`kubectl expose deployment funkyapp1 --name=funkynode --port=80 --target-port=8080 --type=NodePort`

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: funkyapp1 #Selector
  name: funkynode
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
  selector:
    app: funkyapp1
  type: NodePort #Note this!
```

---

This service is available on each node at a specific port.

`kubectl describe svc funkynode`

```bash
Name:                     funkynode
Namespace:                default
Labels:                   app=funkyapp1
Annotations:              cloud.google.com/neg: {"ingress":true}
Selector:                 app=funkyapp1
Type:                     NodePort
IP:                       10.108.5.37
Port:                     <unset>  80/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  30182/TCP
Endpoints:                10.104.2.7:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
```

---

By using the node IP address with the `nodePort` value, we can see the desired payload. Make sure to scale the deployment so that each node is running one replica of the pod. For a cluster with 2 worker nodes, this can be done with `kubectl scale deploy funkyapp1 --replicas=3`.

From there, it is possible to `curl` directly to a node IP address using the `nodePort` when using the shell pod demo. If working from outside the pod network, use the service IP address.

`curl 10.128.0.14:30182`

```bash
CLIENT VALUES:
client_address=10.128.0.14
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://10.128.0.14:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=10.128.0.14:30182
user-agent=curl/7.64.0
BODY:
-no body in request-root
```

### LoadBalancer

- Exposes the Service externally using a cloud provider's load balancer.
- NodePort and ClusterIP Services, to which the external load balancer routes, are automatically created.
- [Source IP for Services with Type LoadBalancer](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-loadbalancer)

`kubectl expose deployment funkyapp1 --name=funkylb --port=80 --target-port=8080 --type=LoadBalancer`

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: funkyapp1
  name: funkylb
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
  selector:
    app: funkyapp1
  type: LoadBalancer #Note this!
```

---

Get information on the `funkylb` service to determine the External IP address.

`kubectl get svc funkylb`

```bash
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
funkylb   LoadBalancer   10.108.11.148   35.232.149.96   80:31679/TCP   64s
```

It is then possible to retrieve the payload using the External IP address and port value from anywhere on the Internet; no need to use the pod shell demo!

`curl 35.232.149.96:80`

```bash
CLIENT VALUES:
client_address=10.104.2.1
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://35.232.149.96:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=35.232.149.96
user-agent=curl/7.55.1
BODY:
-no body in request-
```

### ExternalIP

[Official Documentation](https://kubernetes.io/docs/concepts/services-networking/service/#external-ips)

- Exposes a Kubernetes service on an external IP address.
- Kubernetes has no control over this external IP address.

Here is an example spec:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: MyApp
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 9376
  externalIPs:
    - 80.11.12.10 #Take note!
```

### ExternalName

- Maps the Service to the contents of the externalName field (e.g. foo.bar.example.com), by returning a CNAME record with its value.
- No proxy of any kind is set up.

### Networking Cleanup for Objective 3.3

Run these commands to cleanup the resources, if desired.

```bash
kubectl delete svc funkyip
kubectl delete svc funkynode
kubectl delete svc funkylb
kubectl delete deploy funkyapp1
```

## 3.4 Know How To Use Ingress Controllers And Ingress Resources

Ingress exposes HTTP and HTTPS routes from outside the cluster to services within the cluster.

- Traffic routing is controlled by rules defined on the **Ingress resource**.
- An **Ingress controller** is responsible for fulfilling the Ingress, usually with a load balancer, though it may also configure your edge router or additional frontends to help handle the traffic.
  - For example, the [NGINX Ingress Controller for Kubernetes](https://www.nginx.com/products/nginx/kubernetes-ingress-controller)
- The name of an Ingress object must be a valid DNS subdomain name.
- [Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- A list of [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
- [Katacoda - Create Ingress Routing](https://www.katacoda.com/courses/kubernetes/create-kubernetes-ingress-routes) lab
- [Katacoda - Nginx on Kubernetes](https://www.katacoda.com/javajon/courses/kubernetes-applications/nginx) lab

Example of an ingress resource:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - http:
        paths:
          - path: /testpath
            pathType: Prefix
            backend:
              service:
                name: test
                port:
                  number: 80
```

Information on some of the objects within this resource:

- [Ingress Rules](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules)
- [Path Types](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types)

And, in the case of Nginx, [a custom resource definition (CRD) is often used](https://octopus.com/blog/nginx-ingress-crds) to extend the usefulness of an ingress. An example is shown below:

```yaml
apiVersion: k8s.nginx.org/v1
kind: VirtualServer
metadata:
  name: cafe
spec:
  host: cafe.example.com
  tls:
    secret: cafe-secret
  upstreams:
    - name: tea
      service: tea-svc
      port: 80
    - name: coffee
      service: coffee-svc
      port: 80
  routes:
    - path: /tea
      action:
        pass: tea
    - path: /coffee
      action:
        pass: coffee
```

## 3.5 Know How To Configure And Use CoreDNS

CoreDNS is a general-purpose authoritative DNS server that can serve as cluster DNS.

- A bit of history:
  - As of Kubernetes v1.12, CoreDNS is the recommended DNS Server, replacing `kube-dns`.
  - In Kubernetes version 1.13 and later the CoreDNS feature gate is removed and CoreDNS is used by default.
  - In Kubernetes 1.18, `kube-dns` usage with kubeadm has been deprecated and will be removed in a future version.
- [Using CoreDNS for Service Discovery](https://kubernetes.io/docs/tasks/administer-cluster/coredns/)
- [Customizing DNS Service](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/)

CoreDNS is installed with the following default [Corefile](https://coredns.io/2017/07/23/corefile-explained/) configuration:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
            lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
```

If you need to customize CoreDNS behavior, you create and apply your own ConfigMap to override settings in the Corefile. The [Configuring DNS Servers for Kubernetes Clusters](https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengconfiguringdnsserver.htm) document describes this in detail.

---

Review your configmaps for the `kube-system` namespace to determine if there is a `coredns-custom` configmap.

`kubectl get configmaps --namespace=kube-system`

```bash
NAME                                 DATA   AGE
cluster-kubestore                    0      23h
clustermetrics                       0      23h
extension-apiserver-authentication   6      24h
gke-common-webhook-lock              0      23h
ingress-gce-lock                     0      23h
ingress-uid                          2      23h
kube-dns                             0      23h
kube-dns-autoscaler                  1      23h
metrics-server-config                1      23h
```

---

Create a file named `coredns.yml` containing a configmap with the desired DNS entries in the `data` field such as the example below:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  example.server:
    | # All custom server files must have a “.server” file extension.
    # Change example.com to the domain you wish to forward.
    example.com {
      # Change 1.1.1.1 to your customer DNS resolver.
      forward . 1.1.1.1
    }
```

---

Apply the configmap.

`kubectl apply -f coredns.yml`

---

Validate the existence of the `coredns-custom` configmap.

`kubectl get configmaps --namespace=kube-system`

```bash
NAME                                 DATA   AGE
cluster-kubestore                    0      24h
clustermetrics                       0      24h
coredns-custom                       1      6s
extension-apiserver-authentication   6      24h
gke-common-webhook-lock              0      24h
ingress-gce-lock                     0      24h
ingress-uid                          2      24h
kube-dns                             0      24h
kube-dns-autoscaler                  1      24h
metrics-server-config                1      24h
```

---

Get the configmap and output the value in yaml format.

`kubectl get configmaps --namespace=kube-system coredns-custom -o yaml`

```yaml
apiVersion: v1
data:
  example.server: |
    # Change example.com to the domain you wish to forward.
    example.com {
      # Change 1.1.1.1 to your customer DNS resolver.
      forward . 1.1.1.1
    }
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"example.server":"# Change example.com to the domain you wish to forward.\nexample.com {\n  # Change 1.1.1.1 to your customer DNS resolver.\n  forward . 1.1.1.1\n}\n"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"coredns-custom","namespace":"kube-system"}}
  creationTimestamp: "2020-10-27T19:49:24Z"
  managedFields:
    - apiVersion: v1
      fieldsType: FieldsV1
      fieldsV1:
        f:data:
          .: {}
          f:example.server: {}
        f:metadata:
          f:annotations:
            .: {}
            f:kubectl.kubernetes.io/last-applied-configuration: {}
      manager: kubectl-client-side-apply
      operation: Update
      time: "2020-10-27T19:49:24Z"
  name: coredns-custom
  namespace: kube-system
  resourceVersion: "519480"
  selfLink: /api/v1/namespaces/kube-system/configmaps/coredns-custom
  uid: 8d3250a5-cbb4-4f01-aae3-4e83bd158ebe
```

## 3.6 Choose An Appropriate Container Network Interface Plugin

Generally, it seems that Flannel is good for starting out in a very simplified environment, while Calico (and others) extend upon the basic functionality to meet design-specific requirements.

- [Network Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
- [Choosing a CNI Network Provider for Kubernetes](https://chrislovecnm.com/kubernetes/cni/choosing-a-cni-provider/)
- [Comparing Kubernetes CNI Providers: Flannel, Calico, Canal, and Weave](https://rancher.com/blog/2019/2019-03-21-comparing-kubernetes-cni-providers-flannel-calico-canal-and-weave/)

Common decision points include:

- Network Model: Layer 2, Layer 3, VXLAN, etc.
- Routing: Routing and route distribution for pod traffic between nodes
- Network Policy: Essentially the firewall between network / pod segments
- IP Address Management (IPAM)
- Datastore:
  - `etcd` - for direct connection to an etcd cluster
  - Kubernetes - for connection to a Kubernetes API server
