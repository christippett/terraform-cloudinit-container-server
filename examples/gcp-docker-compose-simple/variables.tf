variable "project" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "region" {
  description = "Google Cloud region where the instance will be created."
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet where the instance will be created."
  type        = string
}

variable "domain" {
  description = "The domain where the app will be hosted."
  type        = string
}

variable "email" {
  description = "Email address used when registering certificates with Let's Encrypt."
  type        = string
}

variable "cloud_dns_zone" {
  description = "Cloud DNS zone name."
  type        = string
}
