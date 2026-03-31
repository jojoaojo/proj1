# base image - an image with openjdk 17
FROM eclipse-temurin:17

# working directory inside docker image
WORKDIR /home/sd

# copy the jar created by assembly to the docker image
COPY target/sd2526-lab1-1.0-jar-with-dependencies.jar sd.jar
COPY exec.sh exec.sh

# run Discovery when starting the docker image
CMD ["java", "-cp", "/home/sd/sd.jar", "sd.lab1.Discovery"]
