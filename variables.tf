

variable "domain" {
  description = "The domain to deploy applications under."
  type = string
}

variable "compose_file" {
  description = "The content of a Compose file used to deploy app(s) on the server."
  type    = string
  default = null
}

variable "container" {
  description = "The container definition to deploy a Docker image on the server."
  type    = any
  default = {}
}

variable "cloudinit_part" {
  description = "Supplementary cloud-init config used to customise instance."
  type = list(object({content_type: string, content: string}))
  default = []
}

/* Lets Encrypt config ------------------------------------------------------ */

variable "enable_letsencrypt" {
  description = "Whether Lets Encrypt certificates should be automatically generated."
  type = bool
  default = true
}

variable "letsencrypt_staging_server" {
  description = "Whether to use the Lets Encrypt staging server (useful for testing)."
  type    = bool
  default = false
}

variable "letsencrypt_email" {
  description = "The email address used for requesting certificates from Lets Encrypt."
  type = string
}

/* Docker config ------------------------------------------------------------ */

variable "docker_log_driver" {
  type = string
  default = "json-file"
}

variable "docker_log_opts" {
  type = map
  default = {}
}

/* Traefik config ----------------------------------------------------------- */

variable "enable_traefik_api" {
  description = "Whether the Traefik dashboard and API should be enabled."
  type    = bool
  default = false
}

variable "traefik_api_user" {
  description = "The username used to access the Traefik dashboard + API."
  type    = string
  default = "admin"
}

variable "traefik_api_password" {
  description = "The password used to access the Traefik dashboard + API."
  type    = string
  default = null
}

variable "traefik_version" {
  description = "The version of Traefik used by the server."
  type    = string
  default = "v2.2"
}
