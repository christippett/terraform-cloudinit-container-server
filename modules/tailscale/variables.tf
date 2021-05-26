variable "authkey" {
  type  = string
}

variable "hostname" {
  type    = string
  default = null
}

variable "advertise_routes" {
  type    = list(string)
  default = []
}

variable "advertise_exit_node" {
  type    = bool
  default = false
}

variable "accept_routes" {
  type    = bool
  default = false
}

variable "accept_dns" {
  type    = bool
  default = true
}
