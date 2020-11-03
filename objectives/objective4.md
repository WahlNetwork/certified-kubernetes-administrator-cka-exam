# Objective 4: Storage

- [Objective 4: Storage](#objective-4-storage)
  - [4.1 Understand Storage Classes, Persistent Volumes](#41-understand-storage-classes-persistent-volumes)
    - [Storage Classes](#storage-classes)
    - [Persistent Volumes](#persistent-volumes)
  - [4.2 Understand Volume Mode, Access Modes And Reclaim Policies For Volumes](#42-understand-volume-mode-access-modes-and-reclaim-policies-for-volumes)
    - [Volume Mode](#volume-mode)
    - [Access Modes](#access-modes)
    - [Reclaim Policies](#reclaim-policies)
  - [4.3 Understand Persistent Volume Claims Primitive](#43-understand-persistent-volume-claims-primitive)
  - [4.4 Know How To Configure Applications With Persistent Storage](#44-know-how-to-configure-applications-with-persistent-storage)

## 4.1 Understand Storage Classes, Persistent Volumes

- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

### Storage Classes

- [Reclaim Policy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy): PersistentVolumes that are dynamically created by a StorageClass will have the reclaim policy specified in the reclaimPolicy field of the class
  - Delete: When PersistentVolumeClaim is deleted, also deletes PersistentVolume and underlying storage object
  - Retain: When PersistentVolumeClaim is deleted, PersistentVolume remains and volume is "released"
- [Volume Binding Mode](https://kubernetes.io/docs/concepts/storage/storage-classes/#volume-binding-mode):
  - `Immediate`: By default, the `Immediate` mode indicates that volume binding and dynamic provisioning occurs once the PersistentVolumeClaim is created
  - `WaitForFirstConsumer`: Delay the binding and provisioning of a PersistentVolume until a Pod using the PersistentVolumeClaim is created
    - Supported by `AWSElasticBlockStore`, `GCEPersistentDisk`, and `AzureDisk`
- [Allow Volume Expansion](https://kubernetes.io/docs/concepts/storage/storage-classes/#allow-volume-expansion): Allow volumes to be expanded
  - Note: It is not possible to reduce the size of a PersistentVolume
- Default Storage Class: A default storage class is used when a PersistentVolumeClaim does not specify the storage class
  - Can be handy when a single default services all pod volumes
- [Provisioner](https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner)
  - Determines the volume plugin to use for provisioning PVs.
  - Example: `gke-pd`, `azure-disk`

---

View all storage classes

`kubectl get storageclass` or `kubectl get sc`

```bash
NAME                 PROVISIONER            RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
standard (default)   kubernetes.io/gce-pd   Delete          Immediate           true                   25h
```

---

View the storage class in yaml format

`kubectl get sc standard -o yaml`

```yaml
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
parameters:
  type: pd-standard
provisioner: kubernetes.io/gce-pd
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

---

Make a custom storage class using the yaml configuration below and save it as `speedyssdclass.yaml`

```yaml
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: speedyssdclass
parameters:
  type: pd-ssd # Note: This will use SSD backed disks
  fstype: ext4
  replication-type: none
provisioner: kubernetes.io/gce-pd
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

---

Apply the storage class configuration to the cluster

`kubectl apply -f speedyssdclass.yaml`

```bash
storageclass.storage.k8s.io/speedyssdclass created
```

---

Get the storage classes

`kubectl get sc`

```bash
NAME                 PROVISIONER            RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
speedyssdclass       kubernetes.io/gce-pd   Retain          WaitForFirstConsumer   true                   5m19s
standard (default)   kubernetes.io/gce-pd   Delete          Immediate              true                   8d
```

### Persistent Volumes

View a persistent volume in yaml format

`kubectl get pv pvc-d2f6e37e-277f-4b7b-8725-542609f1dea4 -o yaml`

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pvc-d2f6e37e-277f-4b7b-8725-542609f1dea4
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 1Gi
  persistentVolumeReclaimPolicy: Delete
  storageClassName: standard
  volumeMode: Filesystem
```

---

Create a new disk named `pv100` in Google Cloud to be used as a persistent volume

> Note: Use the zone of your GKE cluster

`gcloud compute disks create pv100 --size 10GiB --zone=us-central1-c`

---

Make a custom persistent volume using the yaml configuration below and save it as `pv100.yaml`

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv100
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 1Gi
  persistentVolumeReclaimPolicy: Delete
  storageClassName: standard
  volumeMode: Filesystem
  gcePersistentDisk: # This section is required since we are not using a Storage Class
    fsType: ext4
    pdName: pv100
```

---

Apply the persistent volume to the cluster

`kubectl apply -f pv100.yaml`

```bash
persistentvolume/pv100 created
```

---

Get the persistent volume and notice that it has a status of `Available` since there is no `PersistentVolumeClaim` to bind against

`kubectl get pv pv100`

```bash
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pv100   1Gi        RWO            Delete           Available           standard                2m51s
```

## 4.2 Understand Volume Mode, Access Modes And Reclaim Policies For Volumes

- [Volume Mode](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#volume-mode)
- [Access Modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)
- [Reclaim Policy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy)

### Volume Mode

- Filesystem: Kubernetes formats the volume and presents it to a specified mount point.
  - If the volume is backed by a block device and the device is empty, Kuberneretes creates a filesystem on the device before mounting it for the first time.
- Block: Kubernetes exposes a raw block device to the container.
  - Improved time to usage and perhaps performance.
  - The container must know what to do with the device; there is no filesystem.
- Defined in `.spec.volumeMode` for a `PersistentVolumeClaim`.

---

View the volume mode for persistent volume claims using the `-o wide` to see the `VOLUMEMODE` column

`kubectl get pvc -o wide`

```bash
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
www-web-0   Bound    pvc-f3e92637-7e0d-46a3-ad87-ef1275bb5a72   1Gi        RWO            standard       19m   Filesystem
www-web-1   Bound    pvc-d2f6e37e-277f-4b7b-8725-542609f1dea4   1Gi        RWO            standard       19m   Filesystem
```

### Access Modes

- ReadWriteOnce (RWO): can be mounted as read-write by a single node
- ReadOnlyMany (ROX): can be mounted as read-only by many nodes
- ReadWriteMany (RWX): can be mounted as read-write by many nodes
- Defined in `.spec.accessModes` for a `PersistentVolumeClaim` and `PersistentVolume`

View the access mode for persistent volume claims

`kubectl get pvc`

```bash
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
www-web-0   Bound    pvc-f3e92637-7e0d-46a3-ad87-ef1275bb5a72   1Gi        RWO            standard       28m
www-web-1   Bound    pvc-d2f6e37e-277f-4b7b-8725-542609f1dea4   1Gi        RWO            standard       27m
```

### Reclaim Policies

- [Reclaim Policy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy): PersistentVolumes that are dynamically created by a StorageClass will have the reclaim policy specified in the reclaimPolicy field of the class
  - Delete: When PersistentVolumeClaim is deleted, also deletes PersistentVolume and underlying storage object
  - Retain: When PersistentVolumeClaim is deleted, PersistentVolume remains and volume is "released"
- [Change the Reclaim Policy of a PersistentVolume](https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/)
- Defined in `.spec.persistentVolumeReclaimPolicy` for `PersistentVolume`.

---

View the reclaim policy set on persistent volumes

`kubectl get pv`

```bash
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS   REASON   AGE
pvc-d2f6e37e-277f-4b7b-8725-542609f1dea4   1Gi        RWO            Delete           Bound    default/www-web-1   standard                45m
pvc-f3e92637-7e0d-46a3-ad87-ef1275bb5a72   1Gi        RWO            Delete           Bound    default/www-web-0   standard                45m
```

## 4.3 Understand Persistent Volume Claims Primitive

Make a custom persistent volume claim using the yaml configuration below and save it as `pvc01.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc01
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```

---

Apply the persistent volume claim

`kubectl apply -f pvc01.yaml`

```bash
persistentvolumeclaim/pvc01 created
```

---

Get the persistent volume claim

`kubectl get pvc pvc01`

```bash
NAME    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc01   Bound    pvc-9f2e7c5d-b64c-467e-bba6-86ccb333d981   3Gi        RWO            standard       5m19s
```

## 4.4 Know How To Configure Applications With Persistent Storage

- [Configure a Pod to Use a PersistentVolume for Storage](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)

---

Create a new yaml file using the configuration below and save it as `pv-pod.yaml`

> Note: Make sure to create `pvc01` in [this earlier step](#43-understand-persistent-volume-claims-primitive)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pv-pod
spec:
  volumes:
    - name: pv-pod-storage # The name of the volume, used by .spec.containers.volumeMounts.name
      persistentVolumeClaim:
        claimName: pvc01 # This pvc was created in an earlier step
  containers:
    - name: pv-pod-container
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: pv-pod-storage # This refers back to .spec.volumes.name
```

---

Apply the pod

`kubectl apply -f pv-pod.yaml`

```bash
pod/pv-pod created
```

---

Watch the pod provisioning process

`kubectl get pod -w pv-pod`

```bash
NAME     READY   STATUS    RESTARTS   AGE
pv-pod   1/1     Running   0          30s
```

---

View the binding on `pvc01`

`kubectl describe pvc pvc01`

```bash
Name:          pvc01
Namespace:     default
StorageClass:  standard
Status:        Bound
Volume:        pvc-9f2e7c5d-b64c-467e-bba6-86ccb333d981
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: kubernetes.io/gce-pd
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      3Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Mounted By:    pv-pod # Here it is!
Events:
  Type    Reason                 Age   From                         Message
  ----    ------                 ----  ----                         -------
  Normal  ProvisioningSucceeded  36m   persistentvolume-controller  Successfully provisioned volume pvc-9f2e7c5d-b64c-467e-bba6-86ccb333d981 using kubernetes.io/gce-pd
```
