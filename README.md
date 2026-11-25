# SEG3502 — Lab 10: Containers

## What is done

- Added the Dockerfile for the Spring Boot server and updated the Java toolchain to Java 21.
- Configured MySQL using environment variables instead of the Lab 7 H2 runtime database.
- Added the Angular Dockerfile with Nginx.
- Added runtime API URL configuration (env.json, env.template.json and entrypoint.sh) and updated Angular to use it.
- Added the Docker Compose file for MySQL, the server and the client, including the network, volume and health check.
- Added a setup script to import the existing [Lab 7 application](https://github.com/ThunderX500/LAB7) at a pinned revision while preserving the Lab 10 changes.

## What is left to do

- Run the setup script to import the remaining Lab 7 source files.
- Build and run the Docker images and containers locally and verify that the application works.
- Take screenshots Q1, Q2 and Q3.
- Install and start Minikube.
- Create the four Kubernetes YAML files for MySQL, persistent storage, the server and client.
- Load the Docker images into Minikube, apply the manifests, verify deployments and pods, and test port forwarding and pod replacement.
- Take screenshots Q4, Q5 and Q6 and finish the lab report.

Docker configuration is prepared but not runtime-tested. The remaining Lab 7 source files are not yet vendored into this repository. Kubernetes is intentionally left for the second half.

## How to run the Docker part

From the repository root, using Bash (Git Bash on Windows is fine):

```bash
bash prepare-lab7.sh
```

The script imports the missing files from Lab 7, without overwriting the Lab 10 configuration.

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

Capture the actual output of the last command for Q1.

### 2. Angular client (Q2)

```bash
docker build -t books-api-client:latest ./bookstore-client
docker run -d --name booksclient -e API_URL=http://localhost:8080/books-api/ -p 4100:80 books-api-client:latest
docker container ls
```

Open http://localhost:4100 and verify the application. Capture the running containers for Q2.

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
