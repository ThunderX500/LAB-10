# Build the Spring Boot application with Java 21.
FROM gradle:jdk21-alpine AS build
WORKDIR /workspace
COPY . .
RUN chmod +x gradlew && ./gradlew bootJar --no-daemon

# Run the executable JAR.
FROM eclipse-temurin:21-jdk-alpine
WORKDIR /app
EXPOSE 8080
COPY --from=build /workspace/build/libs/*.jar /app/app.jar
HEALTHCHECK --interval=5s --timeout=3s --start-period=60s --retries=24 \
  CMD wget -qO /dev/null http://127.0.0.1:8080/actuator/health/readiness || exit 1
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
