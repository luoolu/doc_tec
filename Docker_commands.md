## Here are some commonly used Docker commands:

-- docker run: Starts a new container from an image. \
$  Example: docker run hello-world \

-- docker ps: Lists all running containers. \
$  Example: docker ps \

-- docker stop: Stops a running container. \
$  Example: docker stop container_name \

-- docker rm: Removes a container. \
$  Example: docker rm container_name \

-- docker images: Lists all images on the local machine. \
$  Example: docker images \

-- docker rmi: Removes an image from the local machine. \
$  Example: docker rmi image_name \

-- docker pull: Pulls an image from a registry. \
$  Example: docker pull image_name \

-- docker push: Pushes an image to a registry. \
$  Example: docker push image_name \

-- docker build: Builds a Docker image from a Dockerfile. \
$  Example: docker build -t image_name Dockerfile_directory \

-- docker exec: Runs a command inside a running container. \
$  Example: docker exec -it container_name command \

-- Enter the container using the docker exec command \
$  docker exec -it container_id_or_name /bin/bash

