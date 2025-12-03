FROM eclipse-temurin:25-jdk AS runtime

WORKDIR /app

# Falls du ein Uber-Jar hast:
COPY target/*-runner.jar ./app.jar

# Optional: wenn du eine expose willst
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
