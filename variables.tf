
variable "config" {
  type = object({
    ca_server  = string
    acme_email = string
    domain     = string
  })
}

variable "services" {
  description = "Map containing Docker Compose service definitions. Refer to the Docker Compose documentation for available options: https://docs.docker.com/compose/compose-file/compose-file-v3/#service-configuration-reference."
  type        = any
  default     = []
}

variable "environment" {
  description = "Map of environment variables to be made available in every running container, as well as used by Docker Compose when parsing its configuration file."
  type        = map(string)
  default     = {}
}

variable "cloudinit" {
  description = "Supplementary cloud-init configuration."
  type        = any
  default     = {}
}

