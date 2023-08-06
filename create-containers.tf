terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_network" "nginx_network" {
  name = "nginx_network"
}

resource "docker_container" "nginx_load_balancer" {
  image = docker_image.nginx_load_balancer.name
  name  = "nginx-load-balancer"

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.nginx_network.name
  }
}

resource "docker_container" "nginx_reverse_proxy" {
  count = var.server_count
  image = docker_image.nginx_reverse_proxy.name
  name  = "nginx-reverse-proxy-${count.index}"
  
  env = [
    "PROXY_ID=nginx-reverse-proxy-${count.index}"
  ]

  ports {
    internal = 80
    external = 8081 + count.index
  }

  networks_advanced {
    name = docker_network.nginx_network.name
  }
}