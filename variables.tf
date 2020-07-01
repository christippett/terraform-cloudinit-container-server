

variable "domain" {
  description = "The domain to deploy applications under."
  type        = string
}

variable "compose_file" {
  description = "The content of a Compose file used to deploy one or more services to the server. Either `container` or `compose_file` must be specified."
  type        = string
  default     = null
}

variable "files" {
  description = "A list of files to upload to the server. Content must be base64 encoded. Files are available under the `/run/app/` directory."
  type        = list(object({ filename : string, content : string }))
  default     = []
}

variable "container" {
  description = "The container definition used to deploy a Docker image to the server. Follows the same schema as a Docker Compose service. Either `container` or `compose_file` must be specified."
  type        = any
  default     = {}
}

variable "cloudinit_part" {
  description = "Supplementary cloud-init config used to customise the instance."
  type        = list(object({ content_type : string, content : string }))
  default     = []
}

/* Lets Encrypt config ------------------------------------------------------ */

variable "enable_letsencrypt" {
  description = "Whether Lets Encrypt certificates should be automatically generated."
  type        = bool
  default     = true
}

variable "letsencrypt_staging_server" {
  description = "Whether to use the Lets Encrypt staging server (useful for testing)."
  type        = bool
  default     = false
}

variable "letsencrypt_email" {
  description = "The email address used for requesting certificates from Lets Encrypt."
  type        = string
}

/* Docker config ------------------------------------------------------------ */

variable "docker_log_driver" {
  description = "Custom Docker log driver (e.g. `gcplogs`)."
  type        = string
  default     = "json-file"
}

variable "docker_log_opts" {
  description = "Additional arguments/options for Docker log driver."
  type        = map
  default     = {}
}

/* Traefik config ----------------------------------------------------------- */

variable "enable_traefik_api" {
  description = "Whether the Traefik dashboard and API should be enabled."
  type        = bool
  default     = false
}

variable "traefik_api_user" {
  description = "The username used to access the Traefik dashboard + API."
  type        = string
  default     = "admin"
}

variable "traefik_api_password" {
  description = "The password used to access the Traefik dashboard + API."
  type        = string
  default     = null
}

variable "traefik_version" {
  description = "The version of Traefik used by the server."
  type        = string
  default     = "v2.2"
}
