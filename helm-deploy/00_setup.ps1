Write-Host "`n # Add Bitnami Helm repo (only once)"
helm repo add bitnami https://charts.bitnami.com/bitnami

Write-Host "`n # Update repo to get latest charts"
helm repo update

Write-Host "`n # Search PostgreSQL chart"
helm search repo bitnami/postgresql

Write-Host "`n # Done. Ready to install PostgreSQL."
