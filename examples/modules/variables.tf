variable "config" {
  type = object({
    project = string
    zone    = string
    name    = string
    subnet  = string
  })
}

variable "tailscale" {
  type = object({
    authkey = string
  })
}

variable "ssh_authorized_key" {
  type = string
}
