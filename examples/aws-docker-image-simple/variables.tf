variable "domain" {
  description = "The domain where the app will be hosted."
  type        = string
}

variable "letsencrypt_email" {
  description = "Email address used when registering certificates with Let's Encrypt."
  type        = string
}

variable "portainer_password" {
  description = "Password to log into Portainer. Must be hashed using `bcrypt`."
  type        = string
}

variable "zone_id" {
  description = "Route53 Zone ID."
  type        = string
}
