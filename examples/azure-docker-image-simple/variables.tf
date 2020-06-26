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

variable "base_resource_name" {
  type        = string
  description = "Used for resource group, DNS name, etc."
}

variable "location" {
  type        = string
  description = "Azure location to which resources should be deployed"
}
