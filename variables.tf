
variable "domain" {
  description = "Server domain to deploy services to."
  type        = string
}

variable "image" {
  description = <<-EOT
    Docker image to deploy as the default service. The service is exposed using
    the port number defined by the `PORT` environment variable (default `80`)
    and can be overridden by specifying a custom value under `var.environment`.
    Ignored if `var.docker_compose` is defined.
  EOT
  type        = string
  default     = null
}

variable "docker_compose" {
  description = <<-EOT
    Docker Compose configuration that will be copied to the server as
    `docker-compose.override.yaml`. Either `var.docker_compose` or `var.image`
    must be defined.
  EOT
  type        = string
  default     = null

  validation {
    condition     = can(yamldecode(coalesce(var.docker_compose, "x-validate:")))
    error_message = "Docker Compose content not valid YAML."
  }
}

variable "environment" {
  description = <<-EOT
    Environment variables that will be saved as a `.env` file and made
    available to Docker Compose and all running containers.
  EOT
  type        = map(string)
  default     = {}

  validation {
    condition     = !anytrue([for k in keys(var.environment) : contains(["DOMAIN"], k)])
    error_message = "One or more environment variables conflict with the internal environment variables used by this module."
  }
}

variable "letsencrypt" {
  description = "Lets Encrypt configuration."
  type = object({
    email  = string
    server = string
  })
  default = {
    email  = null
    server = "staging"
  }
}

variable "cloudinit" {
  description = "Extra cloud-init configuration."
  type        = any
  default     = []
}

