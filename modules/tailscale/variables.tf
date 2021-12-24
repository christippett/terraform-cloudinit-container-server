variable "accept_dns" {
  type        = bool
  default     = null
  description = "Accept DNS configuration from the admin panel (default true)"
}

variable "accept_routes" {
  type        = bool
  default     = null
  description = "Accept routes advertised by other Tailscale nodes (default false)"
}

variable "advertise_exit_node" {
  type        = bool
  default     = null
  description = "Offer to be an exit node for internet traffic for the tailnet (default false)"
}

variable "advertise_routes" {
  type        = list(string)
  default     = []
  description = "Routes to advertise to other nodes (e.g. '10.0.0.0/8' or '192.168.0.0/24')"

  validation {
    condition     = alltrue([for v in var.advertise_routes : can(cidrhost(v, 0))])
    error_message = "Invalid network address."
  }
}

variable "advertise_tags" {
  type        = list(string)
  default     = []
  description = "ACL tags to request"
}

variable "authkey" {
  # sensitive   = true
  description = "Node authorization key"
}

variable "exit_node" {
  type        = string
  default     = null
  description = "Tailscale IP of the exit node for internet traffic"
}

variable "exit_node_allow_lan_access" {
  type        = bool
  default     = null
  description = "Allow direct access to the local network when routing traffic via an exit node (default false)"
}

variable "host_routes" {
  type        = bool
  default     = null
  description = "Install host routes to other Tailscale nodes (default true)"
}

variable "hostname" {
  type        = string
  default     = null
  description = "Hostname to use instead of the one provided by the OS"
}

variable "login_server" {
  type        = string
  default     = null
  description = "Base URL of control server (default https://controlplane.tailscale.com)"
}

variable "netfilter_mode" {
  type        = string
  default     = null
  description = "Netfilter mode (one of on, nodivert, off) (default on)"
  validation {
    condition     = anytrue([for m in [null, "on", "nodivert", "off"] : m == var.netfilter_mode])
    error_message = "Netfilter mode must be one of \"on\", \"nodivert\" or \"off\"."
  }
}

variable "operator" {
  type        = string
  default     = null
  description = "Unix username to allow to operate on tailscaled without sudo"
}

variable "shields_up" {
  type        = bool
  default     = null
  description = "Don't allow incoming connections (default false)"
}

variable "snat_subnet_routes" {
  type        = bool
  default     = null
  description = "Source NAT traffic to local routes advertised with `advertise_routes`"
}
