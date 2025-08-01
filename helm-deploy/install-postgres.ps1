Write-Host "`n # Installing PostgreSQL via Helm..."

helm install postgres-db bitnami/postgresql `
  --set auth.postgresPassword=alexpass `
  --set auth.database=devdb `
  --set primary.persistence.enabled=false `
  --namespace default

Write-Host "`n # PostgreSQL installed. Checking resources..."

kubectl get pods -l app.kubernetes.io/name=postgresql
kubectl get svc -l app.kubernetes.io/name=postgresql
