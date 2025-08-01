Write-Host "`nInstalling MongoDB…"

helm install mongo-db bitnami/mongodb `
  --set auth.rootPassword=rootpass `
  --set auth.username=alex `
  --set auth.password=alexpass `
  --set auth.database=mydb `
  --set architecture=standalone `
  --set persistence.enabled=false

Write-Host "`nChecking resources…"
kubectl get pods -l app.kubernetes.io/name=mongodb
kubectl get svc  -l app.kubernetes.io/name=mongodb
