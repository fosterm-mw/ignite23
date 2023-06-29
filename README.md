# GKE Crossplane Resources

```
make local_dev
```
```
export KUBECONFIG=kubeconfig
```
```
make setup
```

When creating the workload identity for the cluster, crossplane will create a service account to use. Here is an example of creating the new binding: 
```
gcloud iam service-accounts add-iam-policy-binding platform-admin-crossplane@test-app-384114.iam.gserviceaccount.com \
    --member="serviceAccount:test-app-384114.svc.id.goog[crossplane-system/upbound-gcp-provider-c2cb9007bb0b]" --role=roles/iam.serviceAccountTokenCreator \
    --format=json
```

Portforward ArgoCD server
