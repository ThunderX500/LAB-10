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

- Install Docker Desktop and [Minikube](https://minikube.sigs.k8s.io/docs/start/). Neither is installed yet.
- Build and run the Docker images and containers locally and verify that the application works.
- Take screenshots Q1, Q2 and Q3.
- Start Minikube, load the Docker images, apply the manifests, verify deployments and pods, and test port forwarding and pod replacement.
- Take screenshots Q4, Q5 and Q6 and finish the lab report.

The Docker and Kubernetes configuration is complete but not runtime-tested, since neither Docker nor Minikube is installed on this machine.

## How to run the Docker part

The Lab 7 sources are already imported. To re-import them on a fresh clone, run the following from the repository root using Bash (Git Bash on Windows is fine); it will not overwrite the Lab 10 configuration:

```bash
bash prepare-lab7.sh
```

### 1. Spring Boot and MySQL (Q1)

```bash
docker build --network=host -t books-rest-api:latest ./books-rest-api
docker image ls
docker network create mysql-network
docker network ls
docker run -d --name mysqldb --network mysql-network -v mysql-data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=booksDb mysql:9
# Wait for MySQL to finish initialization before starting the server.
docker logs mysqldb
docker run -d --name booksserver --network mysql-network -e MYSQL_USER=root -e MYSQL_PASSWORD=root -e MYSQL_DB=booksDb -e MYSQL_HOST=mysqldb -p 8080:8080 books-rest-api:latest
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
kubectl get deployments
```

Capture the output of `kubectl apply -f .` for Q4 and of `kubectl get deployments` for Q5.

`kubectl apply -f .` starts everything at once, so the `booksserver` pods will report
`CrashLoopBackOff` for the first minute or two: Spring Boot exits when MySQL is not yet accepting
connections, and the pods recover on their own once the `mysql` pod is `Running`. Wait for all of
them with `kubectl get pods -w` before taking the Q5 and Q6 screenshots.

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
kubectl delete pod <booksserver-pod-name>
kubectl get pods
```

Tear everything down with:

```bash
kubectl delete -f .
```

### Notes on the manifests

- The handout's MySQL listing uses `mysql:8` while its own description says `mysql:9`. The manifests use `mysql:9`, which matches the Docker part of the lab.
- The handout's `booksserver` listing sets `replicas: 1` while its description says two replicas, and Q6 asks you to delete one of the two running `booksserver` pods. The manifests use `replicas: 2` so that test works.
- With two server replicas, both pods may run the data seeder against an empty database at the same time and insert the sample authors twice. If the application shows six authors instead of three:

  ```bash
  kubectl scale deployment/booksserver --replicas=0
  kubectl exec deploy/mysql -- mysql -uroot -proot -e "DROP DATABASE booksDb; CREATE DATABASE booksDb;"
  kubectl scale deployment/booksserver --replicas=1   # let one pod seed
  kubectl scale deployment/booksserver --replicas=2
  ```
