
variable "image" {
  description = "Docker image."
  type        = string
  default     = "traefik/whoami"
}

variable "port" {
  description = "Container exposed port."
  type        = number
  default     = 8080
}

variable "domain" {
  description = "Server domain."
  type        = string
}

variable "acme_email" {
  description = "Email used for Let's Encrypt certificate registration."
  type        = string
}

variable "services" {
  description = "Map containing Docker Compose service definitions. Refer to the Docker Compose documentation for available options: https://docs.docker.com/compose/compose-file/compose-file-v3/#service-configuration-reference."
  type        = any
  default     = {}
}

variable "env" {
  description = "Map of environment variables to be made available in every running container, as well as used by Docker Compose when parsing its configuration file."
  type        = map(string)
  default     = {}
}

variable "files" {
  description = "Map of filenames and their base64 encoded content that will be included in the application's working directory (`/var/app`)."
  type        = map(string)
  default     = {}
}

variable "cloud_config" {
  description = "Supplementary cloud-init configuration."
  type        = any
  default     = {}
}

variable "ca_server" {
  description = "CA server to be used by Let's Encrypt (prod|staging)."
  type        = string
  default     = "staging"
}
