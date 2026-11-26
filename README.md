# SEG3502 — Lab 10: Containers

## What is done

- Added the Dockerfile for the Spring Boot server and updated the Java toolchain to Java 21.
- Configured MySQL using environment variables instead of the Lab 7 H2 runtime database.
- Added the Angular Dockerfile with Nginx.
- Added runtime API URL configuration (env.json, env.template.json and entrypoint.sh) and updated Angular to use it.
- Added the Docker Compose file for MySQL, the server and the client, including the network, volume and health check.
- Imported the existing [Lab 7 application](https://github.com/ThunderX500/LAB7) at a pinned revision with `prepare-lab7.sh`, which preserved the Lab 10 changes. The server and client sources are now in this repository.
- Forced LF line endings through `.gitattributes`. The shell scripts had CRLF endings, which makes `entrypoint.sh` unusable inside the Linux container (`exec /entrypoint.sh: no such file or directory`).
- Added the four Kubernetes manifests in `k8s/`: MySQL deployment and service, persistent volume and claim, server deployment and service, client deployment and service.

## What is left to do

- Run the automated integration checks (GitHub Actions → Lab 10 integration tests) or execute the instructions below on a computer with Docker, Minikube and kubectl.
- Take the six real terminal screenshots Q1–Q6 and include them in the lab report.

All required source files, Dockerfiles, Compose configuration and Kubernetes manifests are committed. Startup checks now wait for a usable database and a ready API. The integration workflow tests both deployment methods and records actual command output; it does not generate fabricated screenshots. Runtime status is determined by the workflow result.

## How to run the Docker part

The Lab 7 sources are already imported. No setup script is required. Run the commands from the repository root using Bash (Git Bash on Windows is fine).

### 1. Spring Boot and MySQL (Q1)

```bash
docker build -t books-rest-api:latest ./books-rest-api
docker image ls
docker network create mysql-network
docker network ls
docker run -d --name mysqldb --network mysql-network -v mysql-data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% -e MYSQL_DATABASE=booksDb mysql:9
# Wait until MySQL accepts TCP connections and the database exists.
until docker exec mysqldb mysql --protocol=TCP -h 127.0.0.1 -uroot -proot -D booksDb -e "SELECT 1"; do sleep 3; done
docker run -d --name booksserver --network mysql-network -e MYSQL_USER=root -e MYSQL_PASSWORD=root -e MYSQL_DB=booksDb -e MYSQL_HOST=mysqldb -p 8080:8080 books-rest-api:latest
curl -fsS --retry 90 --retry-delay 2 --retry-all-errors http://localhost:8080/actuator/health/readiness
docker container ls
```

Capture the actual output of the last command for Q1. `curl http://localhost:8080/books-api/books` should return the seeded books.

### 2. Angular client (Q2)

```bash
docker build -t books-api-client:latest ./bookstore-client
docker run -d --name booksclient -e API_URL=http://localhost:8080/books-api/ -p 4100:80 books-api-client:latest
docker container ls
```

Open http://localhost:4100 and verify the application. Capture the running containers for Q2. To confirm that the entrypoint substituted the API URL:

```bash
docker exec booksclient cat /usr/share/nginx/html/assets/env.json
```

### 3. Docker Compose (Q3)

Remove the manually started containers first to avoid port conflicts:

```bash
docker rm -f booksclient booksserver mysqldb
cd docker
docker compose up -d --build
docker compose ps
```

Capture the actual output of `docker compose up -d --build` for Q3. Verify http://localhost:4100 and http://localhost:8080/books-api/books.

```bash
docker compose down
```

The example credentials are for this local lab only, not production.

## How to run the Kubernetes part

The images must be built first, in the Docker part above, because Minikube loads them from the local Docker registry.

### 4. Apply the manifests (Q4 and Q5)

```bash
minikube start
minikube image load books-rest-api:latest
minikube image load books-api-client:latest
cd k8s
kubectl apply -f .
kubectl rollout status deployment/mysql --timeout=6m
kubectl rollout status deployment/booksserver --timeout=6m
kubectl scale deployment/booksserver --replicas=2
kubectl rollout status deployment/booksserver --timeout=6m
kubectl rollout status deployment/booksapp --timeout=6m
kubectl get deployments
```

Capture the output of `kubectl apply -f .` for Q4 and of `kubectl get deployments` for Q5.

MySQL readiness checks and an API init container prevent startup before the database is accepting connections. The API starts with one replica to initialize the empty database safely; after it is ready, scale to two for the replacement exercise.

### 5. Run the application (Q6)

Both port forwards block, so run them in two separate terminals:

```bash
kubectl port-forward service/booksserver 8080:8080
kubectl port-forward service/booksapp 4100:4100
```

The application is then available at http://localhost:4100. List the pods and capture the output for Q6:

```bash
kubectl get pods
```

To demonstrate replication, delete one of the two `booksserver` pods and confirm that a replacement is created:

```bash
kubectl get pods -l app=booksserver
# Replace the example name with a running pod name.
kubectl delete pod <booksserver-pod-name>
kubectl rollout status deployment/booksserver --timeout=6m
kubectl get pods
```

Tear everything down with:

```bash
kubectl delete -f .
```

### Notes on the manifests

- The handout's MySQL listing uses `mysql:8` while its own description says `mysql:9`. The manifests use `mysql:9`, which matches the Docker part of the lab.
- The handout lists one server replica but describes two; use one initially to avoid concurrent schema creation and duplicate seeding, then scale to two as shown above.
- MySQL storage uses a dedicated host directory and a 1 GiB PV/PVC instead of 100 MiB, with a retained volume. This avoids sharing Minikube’s general `/mnt/data` directory.
- The actuator readiness endpoint checks startup and the database. The frontend container serves `env.json` at runtime and supports Angular deep links.

## Verification

While the Docker or Kubernetes services are exposed locally, run `bash scripts/smoke-check.sh` from the repository root to verify the API, seeded data, runtime API URL, frontend route and CORS. The exact seed-count checks assume a fresh lab database. The GitHub Actions workflow repeats these checks for manual Docker, Compose and Kubernetes, then verifies pod replacement. See the Actions tab for the actual result and downloadable command output.
