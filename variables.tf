
variable "domain" {
  description = "Server domain to deploy services to."
  type        = string
}

variable "letsencrypt_email" {
  description = "Email address for registering Let's Encrypt certificates."
  type        = string
}

variable "letsencrypt_server" {
  description = "Let's Encrypt ACME server (prod or staging)."
  type        = string
  default     = "staging"
}

variable "traefik_admin_password" {
  description = "Admin password for accessing Traefik's API and dashboard."
  type        = string
  default     = null
}

variable "services" {
  description = "List of container services to deploy. Refer to the Docker Compose documentation for available options: https://docs.docker.com/compose/compose-file/compose-file-v3/#service-configuration-reference."
  type        = any
  default     = []

  validation {
    condition = alltrue([for s in var.services : contains(keys(s), "image")])
    error_message = "Service definition must include `image` field."
  }
}

variable "docker_compose_file" {
  description = "Path to a Docker Compose file used to override the default configuration included with this module."
  type = string
  default = null

  validation {
    condition = var.docker_compose_file == null || try(fileexists(var.docker_compose_file), false)
    error_message = "Invalid or missing Docker Compose file."
  }
}

variable "environment" {
  description = "Map of environment variables to be made available in every running container, as well as used by Docker Compose when parsing its configuration file."
  type        = map(string)
  default     = {}
}

variable "cloudinit" {
  description = "Supplementary cloud-init configuration."
  type        = any
  default     = []
}

