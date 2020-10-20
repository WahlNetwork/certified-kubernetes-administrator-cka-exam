# Objective 3: Services & Networking

> ⚠ This section is not complete ⚠

- [Objective 3: Services & Networking](#objective-3-services--networking)
  - [3.1 Understand Host Networking Configuration On The Cluster Nodes](#31-understand-host-networking-configuration-on-the-cluster-nodes)
  - [3.2 Understand Connectivity Between Pods](#32-understand-connectivity-between-pods)
  - [3.3 Understand ClusterIP, NodePort, LoadBalancer Service Types And Endpoints](#33-understand-clusterip-nodeport-loadbalancer-service-types-and-endpoints)
    - [ClusterIP](#clusterip)
    - [NodePort](#nodeport)
    - [LoadBalancer](#loadbalancer)
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

[Official Documentation](https://kubernetes.io/docs/concepts/services-networking/service/)

### ClusterIP

- Exposes the Service on a cluster-internal IP. Choosing this value makes the Service only reachable from within the cluster.
- This is the default ServiceType.
- [Using Source IP](https://kubernetes.io/docs/tutorials/services/source-ip/)
- [Kubectl Expose Command Reference](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#expose)

`kubectl create deployment source-ip-app --image=k8s.gcr.io/echoserver:1.4`

`kubectl expose deployment source-ip-app --name=clusterip --port=80 --target-port=8080`

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: source-ip-app
  name: clusterip
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
  selector:
    app: source-ip-app
status:
  loadBalancer: {}
```

### NodePort

- Exposes the Service on each Node's IP at a static port (the NodePort).
- A ClusterIP Service, to which the NodePort Service routes, is automatically created.
- You'll be able to contact the NodePort Service, from outside the cluster, by requesting.
- [Kubectl Patch Command Reference](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#patch)

`kubectl expose deployment source-ip-app --name=nodeport --port=80 --target-port=8080 --type=NodePort`

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: source-ip-app
  name: nodeport
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
  selector:
    app: source-ip-app
  type: NodePort
status:
  loadBalancer: {}
```

```bash
k describe svc nodeport
Name:                     nodeport
Namespace:                default
Labels:                   app=source-ip-app
Annotations:              <none>
Selector:                 app=source-ip-app
Type:                     NodePort
IP:                       10.101.3.213
Port:                     <unset>  80/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  32541/TCP
Endpoints:                192.168.127.193:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
```

`kubectl patch svc nodeport -p '{"spec":{"externalTrafficPolicy":"Local"}}'`

```bash
 k describe svc nodeport
Name:                     nodeport
Namespace:                default
Labels:                   app=source-ip-app
Annotations:              <none>
Selector:                 app=source-ip-app
Type:                     NodePort
IP:                       10.99.87.95
Port:                     <unset>  80/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  32196/TCP
Endpoints:                192.168.127.195:8080
Session Affinity:         None
External Traffic Policy:  Local
Events:                   <none>
```

`for node in $NODES; do curl --connect-timeout 1 -s $node:$NODEPORT | grep -i client_address; done`

### LoadBalancer

- Exposes the Service externally using a cloud provider's load balancer.
- NodePort and ClusterIP Services, to which the external load balancer routes, are automatically created.
- [???MOAR INVESTIGATION IS REQUIRED](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-loadbalancer)

### ExternalName

- Maps the Service to the contents of the externalName field (e.g. foo.bar.example.com), by returning a CNAME record with its value.
- No proxying of any kind is set up.

## 3.4 Know How To Use Ingress Controllers And Ingress Resources

## 3.5 Know How To Configure And Use CoreDNS

## 3.6 Choose An Appropriate Container Network Interface Plugin
