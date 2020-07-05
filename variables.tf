

variable "domain" {
  description = "The domain to deploy applications under."
  type        = string
}

variable "email" {
  description = "The email address used for requesting certificates from Lets Encrypt."
  type        = string
}

variable "letsencrypt_staging" {
  description = "Boolean flag to decide whether the Let's Encrypt staging server should be used."
  type        = bool
  default     = false
}

variable "files" {
  description = "A list of files to upload to the server. Content must be base64 encoded. Files are available under the `/run/app/` directory."
  type        = list(object({ filename : string, content : string }))
  default     = []
}

variable "env" {
  description = "A list environment variables provided as key/value pairs. These can be used to interpolate values within Docker Compsoe files."
  type        = map(string)
  default     = {}
}

variable "container" {
  description = "The container definition used to deploy a Docker image to the server. Follows the same schema as a Docker Compose service."
  type        = any
  default     = {}
}

variable "cloudinit_part" {
  description = "Supplementary cloud-init config used to customise the instance."
  type        = list(object({ content_type : string, content : string }))
  default     = []
}

variable "enable_webhook" {
  description = "Flag whether to enable the webhook endpoint on the server, allowing updates to be made independent of Terraform."
  type        = bool
  default     = false
}
