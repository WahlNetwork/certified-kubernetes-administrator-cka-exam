# Objective 2: Workloads & Scheduling

> ⚠ This section is not complete ⚠

- [Objective 2: Workloads & Scheduling](#objective-2-workloads--scheduling)
  - [2.1 Understand Deployments And How To Perform Rolling Update And Rollbacks](#21-understand-deployments-and-how-to-perform-rolling-update-and-rollbacks)
    - [Perform Rolling Update](#perform-rolling-update)
    - [Perform Rollbacks](#perform-rollbacks)
  - [2.2 Use Configmaps And Secrets To Configure Applications](#22-use-configmaps-and-secrets-to-configure-applications)
    - [Configmaps](#configmaps)
  - [2.3 Know How To Scale Applications](#23-know-how-to-scale-applications)
  - [2.4 Understand The Primitives Used To Create Robust, Self-Healing, Application Deployments](#24-understand-the-primitives-used-to-create-robust-self-healing-application-deployments)
  - [2.5 Understand How Resource Limits Can Affect Pod Scheduling](#25-understand-how-resource-limits-can-affect-pod-scheduling)
  - [2.6 Awareness Of Manifest Management And Common Templating Tools](#26-awareness-of-manifest-management-and-common-templating-tools)

## 2.1 Understand Deployments And How To Perform Rolling Update And Rollbacks

[Official Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#use-case)

[nginx docker hub](https://hub.docker.com/_/nginx)

`kubectl create deployment nginx --image=nginx --replicas=3 -n wahlnetwork1`

`kubectl create deployment nginx --image=nginx --replicas=3 -n wahlnetwork1 --dry-run=client -o yaml`


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

`kubectl set image deployment/nginx nginx=nginx:1.16.1 -n wahlnetwork1 --record`

`kubectl rollout status deployment.v1.apps/nginx -n wahlnetwork1`

```bash
~ kubectl rollout status deployment.v1.apps/nginx -n wahlnetwork1

Waiting for deployment "nginx" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx" rollout to finish: 1 old replicas are pending termination...
deployment "nginx" successfully rolled out
```

### Perform Rollbacks

[Official Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)

`kubectl rollout history deployment.v1.apps/nginx -n wahlnetwork1`

`kubectl rollout undo deployment.v1.apps/nginx -n wahlnetwork1`

```bash
~ kubectl rollout history deployment.v1.apps/nginx -n wahlnetwork1

deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl.exe set image deployment/nginx nginx=nginx:1.16.1 --record=true --namespace=wahlnetwork1
3         kubectl.exe set image deployment/nginx nginx=nginx:1.14.1 --record=true --namespace=wahlnetwork1
4         kubectl.exe set image deployment/nginx nginx=nginx:1.222222222222 --record=true --namespace=wahlnetwork1

~ kubectl rollout undo deployment.v1.apps/nginx -n wahlnetwork1

deployment.apps/nginx rolled back

~ kubectl rollout history deployment.v1.apps/nginx -n wahlnetwork1

deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl.exe set image deployment/nginx nginx=nginx:1.16.1 --record=true --namespace=wahlnetwork1
4         kubectl.exe set image deployment/nginx nginx=nginx:1.222222222222 --record=true --namespace=wahlnetwork1
5         kubectl.exe set image deployment/nginx nginx=nginx:1.14.1 --record=true --namespace=wahlnetwork1
```

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

[Official Documentation](https://kubernetes.io/docs/concepts/configuration/configmap/)

Directory

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

File

`kubectl create configmap game-config-2 --from-file=/code/configmap/game.properties`

Env-File

`kubectl create configmap game-config-env-file --from-env-file=/code/configmap/game-env-file.properties`

Edit

`kubectl get configmaps game-config-2 -o yaml`

## 2.3 Know How To Scale Applications

## 2.4 Understand The Primitives Used To Create Robust, Self-Healing, Application Deployments

## 2.5 Understand How Resource Limits Can Affect Pod Scheduling

## 2.6 Awareness Of Manifest Management And Common Templating Tools
