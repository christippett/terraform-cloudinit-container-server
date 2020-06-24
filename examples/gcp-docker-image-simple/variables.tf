variable "project" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
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
  type = string
}

variable "cloud_dns_zone" {
  type = string
}

variable "letsencrypt_email" {
  type = string
}

variable "traefik_api_user" {
  type = string
}

variable "traefik_api_password" {
  type = string
}

variable "portainer_password" {
  type = string
}
