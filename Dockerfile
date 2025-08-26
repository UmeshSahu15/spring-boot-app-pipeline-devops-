# Use the same base image
FROM openjdk:8-jdk-alpine

# Update Alpine packages to reduce vulnerabilities
RUN apk update && apk upgrade --no-cache

# Set working directory
WORKDIR /opt/app

# Copy your built JAR into the container
COPY target/wezvatech-demo-9739110917.jar app.jar

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
