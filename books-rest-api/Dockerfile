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
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
