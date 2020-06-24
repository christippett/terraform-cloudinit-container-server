variable "project" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "region" {
  description = "Google Cloud region where the instance will be created."
  type        = string
}

variable "zone" {
  description = "Google Cloud region zone where the instance will be created."
  type        = string
}

variable "network_name" {
  description = "The name of the network where the instance will be created."
  type        = string
}

variable "subnetwork_name" {
  description = "The name of the subnet where the instance will be created."
  type        = string
}

variable "domain" {
  description = "The domain where the app will be hosted."
  type        = string
}

variable "letsencrypt_email" {
  description = "Email address used when registering certificates with Let's Encrypt."
  type        = string
}

variable "cloud_dns_zone" {
  description = "Cloud DNS zone name."
  type        = string
}


variable "traefik_api_user" {
  description = "Username to access Traefik dashboard (basic auth)."
  type        = string
}

variable "traefik_api_password" {
  description = "Password to access Traefik dashboard (basic auth). Must be hashed following the `htpasswd` standard."
  type        = string
}
