# Objective 4: Storage

> ⚠ This section is not complete ⚠

- [Objective 4: Storage](#objective-4-storage)
  - [4.1 Understand Storage Classes, Persistent Volumes](#41-understand-storage-classes-persistent-volumes)
  - [4.2 Understand Volume Mode, Access Modes And Reclaim Policies For Volumes](#42-understand-volume-mode-access-modes-and-reclaim-policies-for-volumes)
  - [4.3 Understand Persistent Volume Claims Primitive](#43-understand-persistent-volume-claims-primitive)
  - [4.4 Know How To Configure Applications With Persistent Storage](#44-know-how-to-configure-applications-with-persistent-storage)

## 4.1 Understand Storage Classes, Persistent Volumes

- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

Information on storage classes:

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
  - Example: gke-pd, azure-disk

---

View all storage classes

`kubectl get storageclass`

```bash
NAME                 PROVISIONER            RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
standard (default)   kubernetes.io/gce-pd   Delete          Immediate           true                   25h
```

---

View the storageclass in yaml format

`kubectl get storageclass -o yaml`

```yaml
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
  selfLink: /apis/storage.k8s.io/v1/storageclasses/standard
parameters:
  type: pd-standard
provisioner: kubernetes.io/gce-pd
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

## 4.2 Understand Volume Mode, Access Modes And Reclaim Policies For Volumes

- [Reclaim Policy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy)
- [Change the Reclaim Policy of a PersistentVolume](https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/)

## 4.3 Understand Persistent Volume Claims Primitive

## 4.4 Know How To Configure Applications With Persistent Storage
