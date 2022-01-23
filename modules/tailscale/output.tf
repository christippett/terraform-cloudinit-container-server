data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "${basename(abspath(path.module))}.cfg"
    content      = format("#cloud-config\n%s", yamlencode(local.config))
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
  }
}

output "config" {
  value = data.cloudinit_config.config.part
}

output "user_data" {
  value = data.cloudinit_config.config.rendered
}
