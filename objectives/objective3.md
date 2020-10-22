# Objective 3: Services & Networking

> ⚠ This section is not complete ⚠

- [Objective 3: Services & Networking](#objective-3-services--networking)
  - [3.1 Understand Host Networking Configuration On The Cluster Nodes](#31-understand-host-networking-configuration-on-the-cluster-nodes)
  - [3.2 Understand Connectivity Between Pods](#32-understand-connectivity-between-pods)
  - [3.3 Understand ClusterIP, NodePort, LoadBalancer Service Types And Endpoints](#33-understand-clusterip-nodeport-loadbalancer-service-types-and-endpoints)
    - [ClusterIP](#clusterip)
    - [NodePort](#nodeport)
    - [LoadBalancer](#loadbalancer)
    - [ExternalIP](#externalip)
    - [ExternalName](#externalname)
  - [3.4 Know How To Use Ingress Controllers And Ingress Resources](#34-know-how-to-use-ingress-controllers-and-ingress-resources)
  - [3.5 Know How To Configure And Use CoreDNS](#35-know-how-to-configure-and-use-coredns)
  - [3.6 Choose An Appropriate Container Network Interface Plugin](#36-choose-an-appropriate-container-network-interface-plugin)

## 3.1 Understand Host Networking Configuration On The Cluster Nodes

- Design
  - All nodes can talk
  - All pods can talk (without NAT)
  - Every pod gets a unique IP address
- Network Types

  - Pod Network
  - Node Network
  - Services Network
    - Rewrites egress traffic destinated to a service network endpoint with a pod network IP address

- Proxy Modes
  - IPTables Mode
    - ???
  - IPVS Mode
    - Since 1.11
    - Linux IP Virtual Server (IPVS)
    - L4 load balancer

## 3.2 Understand Connectivity Between Pods

## 3.3 Understand ClusterIP, NodePort, LoadBalancer Service Types And Endpoints

Services are all about abstracting away the details of which pods are running behind a particular network endpoint. For many applications, work must be processed by some other service. Using a service allows the application to "toss over" the work to Kubernetes, which then uses a selector to determine which pods are healthy and available to receive the work. The service abstracts numerous replica pods that are available to do work.

[Official Documentation](https://kubernetes.io/docs/concepts/services-networking/service/)
[Katakoda Networking Introduction](https://www.katacoda.com/courses/kubernetes/networking-introduction)

### ClusterIP

- Exposes the Service on a cluster-internal IP.
- Choosing this value makes the Service only reachable from within the cluster.
- This is the default ServiceType.
- [Using Source IP](https://kubernetes.io/docs/tutorials/services/source-ip/)
- [Kubectl Expose Command Reference](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#expose)

One option is to create a deployment and then expose the deployment. In this example, the deployment is exposed using a ClusterIP service that accepts traffic on port 80 and translates it to the pod using port 8080.

`kubectl create deployment funkyapp1 --image=k8s.gcr.io/echoserver:1.4`

`kubectl expose deployment funkyapp1 --name=funkyip --port=80 --target-port=8080 --type=ClusterIP`

> Note: The `--type=ClusterIP` parameter is optional when deploying a `ClusterIP` service since this is the default type.

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: funkyapp1
  name: funkyip
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
  selector:
    app: funkyapp1
```

Check to make sure the `funkyip` service exists. This also shows the assigned service (cluster IP) address.

```bash
~ kubectl get svc

NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
funkyip      ClusterIP   10.109.9.63   <none>        80/TCP    2s
kubernetes   ClusterIP   10.96.0.1     <none>        443/TCP   20m
```

From there, you can see the endpoint created to match any pod discovered using the `app: funkyapp1` label.

```bash
~ kubectl get endpoints
NAME         ENDPOINTS             AGE
funkyip      192.168.15.214:8080   5s
kubernetes   10.121.8.58:6443      20m
```

The endpoint matches the IP address of the matching pod.

```bash
~ kubectl get pods -o wide

NAME                         READY   STATUS    RESTARTS   AGE     IP               NODE
funkyapp1-65db59f547-sqzzg   1/1     Running   0          3m19s   192.168.15.214   ip-10-121-8-239
```

The `.spec.ports.port` value defines the port used to access the service. The `.spec.ports.targetPort` value defines the port used to access the container's application.

`User -> Port -> Kubernetes Service -> Target Port -> Application`

This can be tested using `curl`:

```bash
export CLUSTER_IP=$(kubectl get services/funkyip -o go-template='{{(index .spec.clusterIP)}}')
echo CLUSTER_IP=$CLUSTER_IP
```

From there, use `curl $CLUSTER_IP:80` to hit the service `port`, which redirects to the `targetPort` of 8080.

### NodePort

- Exposes the Service on each Node's IP at a static port (the NodePort).
- A ClusterIP Service, to which the NodePort Service routes, is automatically created.
- You'll be able to contact the NodePort Service, from outside the cluster, by requesting.
- [Kubectl Patch Command Reference](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#patch)

`kubectl expose deployment funkyapp1 --name=funkynode --port=80 --target-port=8080 --type=NodePort`

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: funkyapp1
  name: funkynode
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
  selector:
    app: funkyapp1
  type: NodePort
```

### LoadBalancer

- Exposes the Service externally using a cloud provider's load balancer.
- NodePort and ClusterIP Services, to which the external load balancer routes, are automatically created.
- [???MOAR INVESTIGATION IS REQUIRED](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-loadbalancer)

### ExternalIP

[Official Documentation](https://kubernetes.io/docs/concepts/services-networking/service/#external-ips)

### ExternalName

- Maps the Service to the contents of the externalName field (e.g. foo.bar.example.com), by returning a CNAME record with its value.
- No proxying of any kind is set up.

## 3.4 Know How To Use Ingress Controllers And Ingress Resources

## 3.5 Know How To Configure And Use CoreDNS

## 3.6 Choose An Appropriate Container Network Interface Plugin
