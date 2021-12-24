
locals {
  authkey_file = "/root/.tailscale/authkey"

  advertise_tags = join(",", [for t in var.advertise_tags : "tag:${trimprefix(t, "tag:")}"])

  opts = {
    accept-dns                 = var.accept_dns
    accept-routes              = var.accept_routes
    advertise-exit-node        = var.advertise_exit_node
    advertise-routes           = join(",", var.advertise_routes)
    advertise-tags             = local.advertise_tags
    authkey                    = "file:${local.authkey_file}"
    exit-node                  = var.exit_node
    exit-node-allow-lan-access = var.exit_node_allow_lan_access
    host-routes                = var.host_routes
    hostname                   = var.hostname
    login-server               = var.login_server
    netfilter-mode             = var.netfilter_mode
    operator                   = var.operator
    shields-up                 = var.shields_up
    snat-subnet-routes         = var.snat_subnet_routes
  }

  flags = [
    for flag, value in local.opts : "--${flag}=${value}"
    if try(length(value) > 0, value != null)
  ]

  config = {
    runcmd = [
      "curl -fsSL https://tailscale.com/install.sh | sh",
      flatten(["tailscale", "up", local.flags])
    ]
    write_files : [
      {
        path    = "/etc/sysctl.d/99-tailscale.conf"
        content = <<-EOT
        net.ipv4.ip_forward = 1
        net.ipv6.conf.all.forwarding = 1
        EOT
      },
      {
        path        = local.authkey_file
        content     = var.authkey
        permissions = "0600"
        defer       = true
      }
    ]
    package_update = true
    packages       = ["curl"]
  }
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "tailscale.cfg"
    content      = format("#cloud-config\n%s", yamlencode(local.config))
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
  }
}
