terraform {
  required_version = ">= 1.3.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

variable "POSTGRES_USER" {
  type    = string
  default = "youruser"
}

variable "POSTGRES_PASSWORD" {
  type    = string
  default = "yourpassword"
}

variable "POSTGRES_DB" {
  type    = string
  default = "yourdbname"
}

variable "POSTGRES_PORT" {
  type    = number
  default = 5432
}

variable "DJANGO_SETTINGS_MODULE" {
  type    = string
  default = "myproject.settings"
}

variable "CELERY_BROKER_URL" {
  type    = string
  default = "redis://redis:6379/0"
}

variable "CELERY_RESULT_BACKEND" {
  type    = string
  default = "redis://redis:6379/1"
}

variable "web_port_internal" {
  type    = number
  default = 8000
}

variable "web_port_external" {
  type    = number
  default = 8006
}

variable "postgres_external_port" {
  type    = number
  default = 8001
}

resource "docker_network" "app_network" {
  name = "app_network"
}

resource "docker_volume" "postgres_data" {
  name = "postgres_data"
}

resource "docker_image" "web" {
  name = "web_image:latest"
  build {
    context    = path.module
    dockerfile = "Dockerfile.web"
  }
}

resource "docker_image" "celery_worker_img" {
  name = "celery_image:latest"
  build {
    context    = path.module
    dockerfile = "Dockerfile.celery"
  }
}

resource "docker_image" "redis" {
  name = "redis:6-alpine"
}

resource "docker_image" "postgres" {
  name = "postgres:13-alpine"
}

resource "docker_container" "redis" {
  name    = "redis"
  image   = docker_image.redis.name
  restart = "unless-stopped"

  ports {
    internal = 6379
    external = 6379
  }

  networks_advanced {
    name = docker_network.app_network.name
  }
}

resource "docker_container" "postgres" {
  name    = "postgres"
  image   = docker_image.postgres.name
  restart = "unless-stopped"

  env = [
    "POSTGRES_USER=${var.POSTGRES_USER}",
    "POSTGRES_PASSWORD=${var.POSTGRES_PASSWORD}",
    "POSTGRES_DB=${var.POSTGRES_DB}"
  ]

  ports {
    internal = 5432
    external = var.postgres_external_port
  }

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name = docker_network.app_network.name
  }
}

resource "docker_container" "web" {
  name        = "web"
  image       = docker_image.web.name
  restart     = "unless-stopped"
  binds       = ["${path.module}:/app"]
  working_dir = "/app"

  env = [
    "DJANGO_SETTINGS_MODULE=${var.DJANGO_SETTINGS_MODULE}",
    "POSTGRES_HOST=postgres",
    "POSTGRES_PORT=${var.POSTGRES_PORT}",
    "POSTGRES_USER=${var.POSTGRES_USER}",
    "POSTGRES_PASSWORD=${var.POSTGRES_PASSWORD}",
    "POSTGRES_DB=${var.POSTGRES_DB}",
    "CELERY_BROKER_URL=${var.CELERY_BROKER_URL}",
    "CELERY_RESULT_BACKEND=${var.CELERY_RESULT_BACKEND}"
  ]

  ports {
    internal = var.web_port_internal
    external = var.web_port_external
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [
    docker_container.redis,
    docker_container.postgres
  ]
}

resource "docker_container" "celery_worker" {
  name        = "celery-worker"
  image       = docker_image.celery_worker_img.name
  restart     = "unless-stopped"
  binds       = ["${path.module}:/app"]
  working_dir = "/app"

  env = [
    "DJANGO_SETTINGS_MODULE=${var.DJANGO_SETTINGS_MODULE}",
    "POSTGRES_HOST=postgres",
    "POSTGRES_PORT=${var.POSTGRES_PORT}",
    "POSTGRES_USER=${var.POSTGRES_USER}",
    "POSTGRES_PASSWORD=${var.POSTGRES_PASSWORD}",
    "POSTGRES_DB=${var.POSTGRES_DB}",
    "CELERY_BROKER_URL=${var.CELERY_BROKER_URL}",
    "CELERY_RESULT_BACKEND=${var.CELERY_RESULT_BACKEND}"
  ]

  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [
    docker_container.redis,
    docker_container.postgres
  ]
}
