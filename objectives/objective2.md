# Objective 2: Workloads & Scheduling

- [Objective 2: Workloads & Scheduling](#objective-2-workloads--scheduling)
  - [2.1 Understand Deployments And How To Perform Rolling Update And Rollbacks](#21-understand-deployments-and-how-to-perform-rolling-update-and-rollbacks)
    - [Create Deployment](#create-deployment)
    - [Perform Rolling Update](#perform-rolling-update)
    - [Perform Rollbacks](#perform-rollbacks)
  - [2.2 Use Configmaps And Secrets To Configure Applications](#22-use-configmaps-and-secrets-to-configure-applications)
    - [Configmaps](#configmaps)
    - [Secrets](#secrets)
    - [Other Concepts](#other-concepts)
  - [2.3 Know How To Scale Applications](#23-know-how-to-scale-applications)
  - [2.4 Understand The Primitives Used To Create Robust, Self-Healing, Application Deployments](#24-understand-the-primitives-used-to-create-robust-self-healing-application-deployments)
  - [2.5 Understand How Resource Limits Can Affect Pod Scheduling](#25-understand-how-resource-limits-can-affect-pod-scheduling)
  - [2.6 Awareness Of Manifest Management And Common Templating Tools](#26-awareness-of-manifest-management-and-common-templating-tools)

## 2.1 Understand Deployments And How To Perform Rolling Update And Rollbacks

[Official Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#use-case)

Deployments are used to manage Pods and ReplicaSets in a declarative manner.

### Create Deployment

Using the [nginx](https://hub.docker.com/_/nginx) image on Docker Hub, we can use a Deployment to push any number of replicas of that image to the cluster.

Create the `nginx` deployment in the `wahlnetwork1` namespace.

`kubectl create deployment nginx --image=nginx --replicas=3 -n wahlnetwork1`

> Alternatively, use `kubectl create deployment nginx --image=nginx --replicas=3 -n wahlnetwork1 --dry-run=client -o yaml` to output a proper yaml configuration.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nginx
  name: nginx
  namespace: wahlnetwork1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx
    spec:
      containers:
        - image: nginx
          name: nginx
          resources: {}
```

### Perform Rolling Update

[Official Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment)

Used to make changes to the pod's template and roll them out to the cluster. Triggered when data within `.spec.template` is changed.

Update the `nginx` deployment in the `wahlnetwork1` namespace to use version `1.16.1`

`kubectl set image deployment/nginx nginx=nginx:1.16.1 -n wahlnetwork1 --record`

Track the rollout status.

`kubectl rollout status deployment.v1.apps/nginx -n wahlnetwork1`

```bash
Waiting for deployment "nginx" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx" rollout to finish: 1 old replicas are pending termination...
deployment "nginx" successfully rolled out
```

### Perform Rollbacks

[Official Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)

Rollbacks offer a method for reverting the changes to a pod's `.spec.template` data to a previous version. By default, executing the `rollout undo` command will revert to the previous version. The desired version can also be declared.

Review the version history for the `nginx` deployment in the `wahlnetwork1` namespace. In this scenario, other revisions 1-4 have been made to simulate a deployment lifecycle. The 4th revision specifies a fake image version of `1.222222222222` to force a rolling update failure.

`kubectl rollout history deployment.v1.apps/nginx -n wahlnetwork1`

```bash
deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl.exe set image deployment/nginx nginx=nginx:1.16.1 --record=true --namespace=wahlnetwork1
3         kubectl.exe set image deployment/nginx nginx=nginx:1.14.1 --record=true --namespace=wahlnetwork1
4         kubectl.exe set image deployment/nginx nginx=nginx:1.222222222222 --record=true --namespace=wahlnetwork1
```

Revert to the previous version of the `nginx` deployment to use image version `1.14.1`. This forces revision 3 to become revision 5. Note that revision 3 no longer exists.

`kubectl rollout undo deployment.v1.apps/nginx -n wahlnetwork1`

```bash
deployment.apps/nginx rolled back

~ kubectl rollout history deployment.v1.apps/nginx -n wahlnetwork1

deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl.exe set image deployment/nginx nginx=nginx:1.16.1 --record=true --namespace=wahlnetwork1
4         kubectl.exe set image deployment/nginx nginx=nginx:1.222222222222 --record=true --namespace=wahlnetwork1
5         kubectl.exe set image deployment/nginx nginx=nginx:1.14.1 --record=true --namespace=wahlnetwork1
```

Revert to revision 2 of the `nginx` deployment, which becomes revision 6 (the next available revision number). Note that revision 2 no longer exists.

`kubectl rollout undo deployment.v1.apps/nginx -n wahlnetwork1 --to-revision=2`

```bash
~ kubectl rollout history deployment.v1.apps/nginx -n wahlnetwork1

deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
4         kubectl.exe set image deployment/nginx nginx=nginx:1.222222222222 --record=true --namespace=wahlnetwork1
5         kubectl.exe set image deployment/nginx nginx=nginx:1.14.1 --record=true --namespace=wahlnetwork1
6         kubectl.exe set image deployment/nginx nginx=nginx:1.16.1 --record=true --namespace=wahlnetwork1
```

## 2.2 Use Configmaps And Secrets To Configure Applications

### Configmaps

API object used to store non-confidential data in key-value pairs

- [Official Documentation](https://kubernetes.io/docs/concepts/configuration/configmap/)
  [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

Create a configmap named `game-config` using a directory.

`kubectl create configmap game-config --from-file=/code/configmap/`

```bash
~ k describe configmap game-config

Name:         game-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
game.properties:
----
enemies=aliens
lives=3
enemies.cheat=true
enemies.cheat.level=noGoodRotten
secret.code.passphrase=UUDDLRLRBABAS
secret.code.allowed=true
secret.code.lives=30

ui.properties:
----
color.good=purple
color.bad=yellow
allow.textmode=true
how.nice.to.look=fairlyNice

Events:  <none>
```

Create a configmap named `game-config` using a file.

`kubectl create configmap game-config-2 --from-file=/code/configmap/game.properties`

Create a configmap named `game-config` using an env-file.

`kubectl create configmap game-config-env-file --from-env-file=/code/configmap/game-env-file.properties`

Create a configmap named `special-config` using a literal key/value pair.

`kubectl create configmap special-config --from-literal=special.how=very`

Edit a configmap named `game-config`.

`kubectl edit configmap game-config`

Get a configmap named `game-config` and output the response into yaml.

`kubectl get configmaps game-config -o yaml`

Use a configmap with a pod by declaring a value for `.spec.containers.env.name.valueFrom.configMapKeyRef`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      image: k8s.gcr.io/busybox
      command: ["/bin/sh", "-c", "env"]
      env:
        # Define the environment variable
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              # The ConfigMap containing the value you want to assign to SPECIAL_LEVEL_KEY
              name: special-config
              # Specify the key associated with the value
              key: special.how
  restartPolicy: Never
```

Investigate the configmap value `very` from the key `SPECIAL_LEVEL_KEY` by reviewing the logs for the pod or by connecting to the pod directly.

`kubectl exec -n wahlnetwork1 --stdin nginx-6889dfccd5-msmn8 --tty -- /bin/bash`

```bash
~ kubectl logs dapi-test-pod

KUBERNETES_SERVICE_PORT=443
KUBERNETES_PORT=tcp://10.96.0.1:443
HOSTNAME=dapi-test-pod
SHLVL=1
HOME=/root
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_PROTO=tcp
SPECIAL_LEVEL_KEY=very
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_SERVICE_PORT_HTTPS=443
PWD=/
KUBERNETES_SERVICE_HOST=10.96.0.1
```

### Secrets

- [Managing Secret using kubectl](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/)
- [Using Secrets](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets)

Create a secret named `db-user-pass` using files.

```bash
kubectl create secret generic db-user-pass `
  --from-file=./username.txt `
  --from-file=./password.txt
```

The key name can be modified by inserting a key name into the file path. For example, setting the key names to `funusername` and `funpassword` can be done as shown below:

```bash
kubectl create secret generic fundb-user-pass `
  --from-file=funusername=./username.txt `
  --from-file=funpassword=./password.txt
```

Check to make sure the key names matches the defined names.

`kubectl describe secret fundb-user-pass`

```bash
Name:         fundb-user-pass
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
funpassword:  14 bytes
funusername:  7 bytes
```

Get secret values from `db-user-pass`.

`kubectl get secret db-user-pass -o jsonpath='{.data}'`

Edit secret values using the `edit` command.

`kubectl edit secrets db-user-pass`

```yaml
apiVersion: v1
data:
  password.txt: PASSWORD
  username.txt: USERNAME
kind: Secret
metadata:
  creationTimestamp: "2020-10-13T22:48:27Z"
  name: db-user-pass
  namespace: default
  resourceVersion: "1022459"
  selfLink: /api/v1/namespaces/default/secrets/db-user-pass
  uid: 6bb24810-dd33-4b92-9a37-424f3c7553b6
type: Opaque
```

Use a secret with a pod by declaring a value for `.spec.containers.env.name.valueFrom.secretKeyRef`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-env-pod
spec:
  containers:
    - name: mycontainer
      image: redis
      env:
        - name: SECRET_USERNAME
          valueFrom:
            secretKeyRef:
              name: mysecret
              key: username
        - name: SECRET_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysecret
              key: password
  restartPolicy: Never
```

### Other Concepts

- [Using imagePullSecrets](https://kubernetes.io/docs/concepts/configuration/secret/#using-imagepullsecrets)

## 2.3 Know How To Scale Applications

Scaling is accomplished by changing the number of replicas in a Deployment.

- [Running Multiple Instances of Your App](https://kubernetes.io/docs/tutorials/kubernetes-basics/scale/scale-intro/)

Scale a deployment named `nginx` from 3 to 4 replicas.

`kubectl scale deployments/nginx --replicas=4`

## 2.4 Understand The Primitives Used To Create Robust, Self-Healing, Application Deployments

- Don't use naked Pods (that is, Pods not bound to a ReplicaSet or Deployment) if you can avoid it. Naked Pods will not be rescheduled in the event of a node failure. ([source](https://kubernetes.io/docs/concepts/configuration/overview/#naked-pods-vs-replicasets-deployments-and-jobs))
- A Deployment, which both creates a ReplicaSet to ensure that the desired number of Pods is always available, and specifies a strategy to replace Pods (such as RollingUpdate), is almost always preferable to creating Pods directly, except for some explicit `restartPolicy: Never` scenarios. A Job may also be appropriate. ([source](https://kubernetes.io/docs/concepts/configuration/overview/#naked-pods-vs-replicasets-deployments-and-jobs))
- Define and use labels that identify semantic attributes of your application or Deployment, such as `{ app: myapp, tier: frontend, phase: test, deployment: v3 }`. ([source](https://kubernetes.io/docs/concepts/configuration/overview/#using-labels))

## 2.5 Understand How Resource Limits Can Affect Pod Scheduling

Resource limits are a mechanism to control the amount of resources needed by a container. This commonly translates into CPU and memory limits.

- Limits set an upper boundary on the amount of resources a container is allowed to consume from the host.
- Requests set an upper boundary on the amount of resources a container is allowed to consume from the host.
- If a limit is set without a request, the request value is set to equal the limit value.
- [Managing Resources for Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)

Here is an example of pod configured with resource requests and limits.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend
spec:
  containers:
    - name: app
      image: images.my-company.example/app:v4
      resources:
        requests:
          memory: "64Mi"
          cpu: "250m"
        limits:
          memory: "128Mi"
          cpu: "500m"
    - name: log-aggregator
      image: images.my-company.example/log-aggregator:v6
      resources:
        requests:
          memory: "64Mi"
          cpu: "250m"
        limits:
          memory: "128Mi"
          cpu: "500m"
```

## 2.6 Awareness Of Manifest Management And Common Templating Tools

- [Templating YAML in Kubernetes with real code](https://learnk8s.io/templating-yaml-with-code)
- [yq](https://github.com/kislyuk/yq): Command-line YAML/XML processor
- [kustomize](https://github.com/kubernetes-sigs/kustomize): lets you customize raw, template-free YAML files for multiple purposes, leaving the original YAML untouched and usable as is.
- [Helm](https://github.com/helm/helm): A tool for managing Charts. Charts are packages of pre-configured Kubernetes resources.
