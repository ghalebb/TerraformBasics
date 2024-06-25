#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker Engine
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER

# Create a docker-compose.yml file for the Netflix stack
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  nginx:
    image: nginx:latest
    ports:
      - "8081:80"
    networks:
      - public-net-1
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/nginx.conf
    depends_on:
      - netflix-front

  netflix-front:
    image: ghalebb/netflix_front:0.0.2
    ports:
      - "3000:3000"
    networks:
      - public-net-1
      - private-net-1
    environment:
      - MOVIE_CATALOG_SERVICE=http://internal-galeb-load-balancer-256650963.us-east-2.elb.amazonaws.com:8080
      - AWS_REGION=us-east-2
      - AWS_S3_BUKCET=galeb-aws-bucket
    depends_on:
      - netflix_movie_catalog

  netflix_movie_catalog:
    image: ghalebb/netflix_movie_catalog:0.0.1
    ports:
      - "8080:8080"
    networks:
      - private-net-1

networks:
  public-net-1:
    driver: bridge
  private-net-1:
    driver: bridge
EOF

# Run the Netflix stack in the background
sudo docker-compose up -d

echo "Docker and Netflix stack have been successfully installed and started."
