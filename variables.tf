

variable "domain" {
  description = "The domain to deploy applications under."
  type        = string
}

variable "email" {
  description = "The email address used for requesting certificates from Lets Encrypt."
  type        = string
}

variable "image" {
  description = "Rapidly deploy a service by specifying only a Docker image."
  type        = string
  default     = ""
}

variable "port" {
  description = "Default port exposed by the application container."
  type        = string
  default     = ""
}

variable "network" {
  description = "Default network name used by Traefik to identify services."
  type        = string
  default     = "traefik"
}


variable "services" {
  description = "Map containing a service definition and having the same schema as expected by Docker Compose (https://docs.docker.com/compose/compose-file/compose-file-v3/#service-configuration-reference)."
  type        = any
  default     = {}
}

variable "env" {
  description = "List of environment variables (KEY=VAL) to be made available within running containers and also Docker Compose configuration files."
  type        = map(string)
  default     = {}
}

variable "files" {
  description = "Map of filenames and their base64 encoded content to be copied to the application's working directory (`/var/app`)."
  type        = map(string)
  default     = {}
}

variable "cloudinit_extra" {
  description = "Additional cloud-init configuration for setting up or customising the instance beyond the defaults provided by this module."
  type        = any
  default     = {}
}

variable "letsencrypt_server" {
  description = "Configure which Let's Encrypt server to use, either 'prod' or 'staging' (default)."
  type        = string
  default     = "staging"
}

variable "webhook_enabled" {
  description = "Enabling this feature will expose an endpoint (`/webhook/update-env`) on the server allowing updates to be made to the application's environment variables via a HTTP PATCH request. Updates will trigger the application to be restarted and the latest image to be pulled."
  type        = bool
  default     = false
}

variable "appdir" {
  description = "Working directory on the remote instance where the application will be run."
  type        = string
  default     = "/var/app"
}
