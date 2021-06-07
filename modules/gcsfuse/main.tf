
locals {
  config = {
    package_upgrade = true
    package_update  = true
    apt = {
      preserve_sources_list = true
      sources = {
        gcsfuse = {
          source = "deb http://packages.cloud.google.com/apt gcsfuse-focal main"
        }
      }
    }
    packages = ["gcsfuse"]
    mounts = [[
      var.bucket, var.mount_dir, "gcsfuse",
      "rw,x-systemd.requires=network-online.target,user"
    ]]

    # google uses two signing keys, this causes problems when it comes to
    # importing their keys from cloudinit - we need to add the key separately
    # before the apt module runs.
    bootcmd = ["curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -"]
    runcmd  = ["mkdir -p ${var.mount_dir} && gcsfuse ${var.bucket} ${var.mount_dir}"]
  }
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "gcsfuse.cfg"
    content      = join("\n", ["#cloud-config", yamlencode(local.config)])
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
  }
}
