# Use a more recent OpenJDK 8 Alpine base image
FROM openjdk:8-jdk-alpine3.18

# Reduce vulnerabilities by updating Alpine packages
RUN apk update && apk upgrade --no-cache \
    && rm -rf /var/cache/apk/*

# Set working directory inside container
WORKDIR /opt/app

# Copy your built JAR into the container
COPY target/wezvatech-demo-9739110917.jar app.jar

# Expose the default application port (if your app runs on 8080)
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
