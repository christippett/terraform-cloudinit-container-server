
locals {
  enable_ip_forwarding = <<-EOT
    enable_property() {
      printf 'Setting `%s=1`' "$2"
      fn="$(basename "$1")"
      sed -r 's/#{1,}?'"$2"'=(0|1)/'"$2"'=1/g' "$1" > "/tmp/$fn"
      mv "/tmp/$fn" "$1"
    }
    enable_property /etc/sysctl.conf net.ipv4.ip_forward
    enable_property /etc/sysctl.conf net.ipv6.conf.all.forwarding
    sysctl -p
  EOT


  tailscale_flags = flatten([
    "--authkey ${var.authkey}",
    var.hostname != null ? ["--hostname ${var.hostname}"] : [],
    var.accept_routes ? ["--accept-routes"] : [],
    var.accept_dns ? ["--accept-dns"] : [],
    var.advertise_exit_node ? ["--advertise-exit-node"] : [],
    (
      length(var.advertise_routes) > 0
      ? ["--advertise-routes ${join(",", var.advertise_routes)}"]
      : []
    )
  ])

  config = {
    package_upgrade = true
    package_update  = true
    apt = {
      preserve_sources_list = true
      sources = {
        tailscale = {
          source    = "deb https://pkgs.tailscale.com/stable/ubuntu focal main"
          keyid     = "957F5868"
          keyserver = "https://pkgs.tailscale.com/stable/ubuntu/focal.gpg"
        }
      }
    }
    packages = ["tailscale"]
    runcmd = flatten([
      length(var.advertise_routes) > 0 ? [local.enable_ip_forwarding] : [],
      "tailscale up ${join(" \\\n  ", local.tailscale_flags)}"
    ])
  }
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "tailscale.cfg"
    content      = join("\n", ["#cloud-config", yamlencode(local.config)])
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
  }
}
