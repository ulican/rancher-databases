# Deploying PostgreSQL on Rancher Desktop (K3s)

Spin up a PostgreSQL instance inside a local **Rancher Desktop** (K3s) cluster and verify connectivity with an interactive CLI pod.

---

## 1 · Prerequisites

| Tool                           | Minimum Version | Purpose                                |
| ------------------------------ | --------------- | -------------------------------------- |
| Rancher Desktop                | latest          | Runs the local K3s cluster             |
| `kubectl`                      |  v1.33+         | Interact with Kubernetes               |
| **Helm**                       |  v3.18+         | Install packaged applications (charts) |
| **PowerShell**                 |  v5+            | Primary CLI used in this guide         |
| **VS Code** (+ Helm extension) | –               | Edit scripts / YAML                    |
| **Git** (optional)             | –               | Version‑control the project            |

> **Tip :** Ensure Rancher Desktop shows **“Kubernetes Running”** before continuing.

---

## 2 · Folder Layout

```text
rancher-databases/
├── helm-deploy/
│   ├── 00_setup.ps1          # add & update Helm repo
│   └── install-postgres.ps1  # deploy PostgreSQL
├── manifests/
│   └── client-pod.yaml       # lightweight shell pod
└── test/                     # (future) CRUD test scripts
```

Create the directories:

```powershell
mkdir rancher-databases; cd rancher-databases
mkdir helm-deploy, manifests, test
```

---

## 3 · Step‑by‑Step

### 3.1 Add the Bitnami Helm Repository

**`helm-deploy/00_setup.ps1`**

```powershell
Write-Host "`nAdding Bitnami repo…"
helm repo add bitnami https://charts.bitnami.com/bitnami

Write-Host "`nUpdating repo…"
helm repo update

Write-Host "`nVerifying PostgreSQL chart…"
helm search repo bitnami/postgresql
```

Run the script:

```powershell
.\helm-deploy\00_setup.ps1
```

### 3.2 Install PostgreSQL

**`helm-deploy/install-postgres.ps1`**

```powershell
Write-Host "`nInstalling PostgreSQL…"

helm install postgres-db bitnami/postgresql `
  --set auth.postgresPassword=alexpass `
  --set auth.database=devdb `
  --set primary.persistence.enabled=false

Write-Host "`nChecking resources…"
kubectl get pods -l app.kubernetes.io/name=postgresql
kubectl get svc  -l app.kubernetes.io/name=postgresql
```

Execute:

```powershell
.\helm-deploy\install-postgres.ps1
```

Expected result: pod `postgres-db-postgresql-0` **Running**, service `postgres-db-postgresql` on port **5432**.

### 3.3 Launch an Interactive Client Pod

**`manifests/client-pod.yaml`**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: client
spec:
  containers:
    - name: client
      image: bitnami/minideb
      command: ["/bin/bash", "-c", "sleep infinity"]
      stdin: true
      tty: true
```

Apply & open a shell:

```powershell
kubectl apply -f manifests\client-pod.yaml
kubectl exec -it client -- bash
```

### 3.4 Connect & CRUD Test

Inside **client** pod:

```bash
apt update && apt install -y postgresql-client
psql -h postgres-db-postgresql -U postgres -d devdb   # password: alexpass
```

Run a minimal CRUD cycle:

```sql
CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT, email TEXT);
INSERT INTO users(name,email) VALUES ('Alex','alex@example.com');
SELECT * FROM users;
UPDATE users SET name = 'Alex Updated' WHERE id = 1;
DELETE FROM users WHERE id = 1;
\q
```

Exit pod shell:

```bash
exit
```

---

## 4 · Next Steps

1. **Add more databases**   `helm install bitnami/mongodb …`, Helm chart for MSSQL, etc.
2. **Automate tests**   create scripts in `test/` (e.g. `postgres-crud.ps1`).
3. **Enable persistence**   remove `--set primary.persistence.enabled=false`.
4. **Port‑forward for host access**   `kubectl port-forward svc/postgres-db-postgresql 5432:5432`.

---

## 5 · Clean‑up

```powershell
helm uninstall postgres-db
kubectl delete pod client
```

---

Happy Helming — feel free to fork / improve / share! 🐳🚀

---







## 1 · MongoDB Deployment & CRUD

### 1.1 Install MongoDB with Helm

**`helm-deploy/install-mongo.ps1`**

```powershell
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
```

Run it:

```powershell
.\helm-deploy\install-mongo.ps1
```

Expected: pod `mongo-db-mongodb-xxxxxx` in **Running**, service `mongo-db-mongodb` on port **27017**.

### 1.2 Connect & CRUD Test (MongoDB)

From PowerShell, launch a temporary test pod:

```powershell
kubectl run mongo-client --rm -it --restart=Never `
  --image docker.io/bitnami/mongodb:8.0.12-debian-12-r0 --command -- bash
```

Inside that pod:

```bash
mongosh "mongodb://alex:alexpass@mongo-db-mongodb:27017/mydb" --eval '
  db.users.insertOne({ name: "Alex", email: "alex@example.com" });
  db.users.find();
  db.users.updateOne({ name: "Alex" }, { $set: { name: "Alex Updated" } });
  db.users.deleteOne({ name: "Alex Updated" });
'
exit
```

### 1.3 Clean-up

```powershell
helm uninstall mongo-db
```








## 5 · MSSQL Deployment & CRUD

### 5.1 Deploy Microsoft SQL Server with YAML

**`manifests/mssql-deployment.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mssql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mssql
  template:
    metadata:
      labels:
        app: mssql
    spec:
      containers:
      - name: mssql
        image: mcr.microsoft.com/mssql/server:2019-latest
        ports:
        - containerPort: 1433
        env:
        - name: ACCEPT_EULA
          value: "Y"
        - name: SA_PASSWORD
          value: "YourStrong!Passw0rd"
---
apiVersion: v1
kind: Service
metadata:
  name: mssql
spec:
  selector:
    app: mssql
  ports:
  - port: 1433
    targetPort: 1433
    protocol: TCP
  type: ClusterIP
```

Apply it:

```powershell
kubectl apply -f .\manifests\mssql-deployment.yaml
kubectl get pods -l app=mssql -w
kubectl get svc mssql
```

Expected: pod `mssql-xxxxx` **Running**, service `mssql` on port **1433**.

### 5.2 Connect & CRUD Test (MSSQL)

From PowerShell, launch a temporary client pod:

```powershell
kubectl run mssql-client --rm -it --restart=Never --image=mcr.microsoft.com/mssql-tools --command -- bash
```

Inside that pod:

```bash
sqlcmd -S mssql -U sa -P 'YourStrong!Passw0rd'
```

When you see the prompt `1>`, run these commands one by one:

```sql
CREATE TABLE users(id INT, name NVARCHAR(100));
GO

INSERT INTO users VALUES (1, 'Alex');
GO

SELECT * FROM users;
GO

UPDATE users SET name='Alex Updated' WHERE id=1;
GO

DELETE FROM users WHERE id=1;
GO

QUIT
```

Exit the pod shell:

```bash
exit
```

### 5.3 Clean-up

```powershell
kubectl delete -f .\manifests\mssql-deployment.yaml
```

