locals {
  asdf = defaults(var.asdf, {
    version  = "v0.9.0"
    dir      = "/opt/asdf"
    data_dir = "/opt/asdf"
  })

  groups = distinct(flatten([for _, u in var.users : [for g in coalesce(u.groups, []) : g]]))

  users = concat(
    ["default"],
    [
      for username, usercfg in var.users : merge(
        usercfg,
        { "name" : username, "groups" : try(join(",", usercfg.groups), usercfg.groups) }
      )
    ]
  )



  config = {
    package_update  = true
    package_upgrade = true
    packages        = var.apt != null ? var.apt.packages : []

    apt = {
      preserve_sources_list = true
      sources = {
        fish = { source = "ppa:fish-shell/release-3" }
      }
    }

    write_files = flatten([
      {
        path    = "/etc/environment"
        content = join("\n", ["ASDF_DIR=${local.asdf.dir}", "ASDF_DATA_DIR=${local.asdf.data_dir}"])
        append  = true
      },
      [
        for fp in fileset("${path.module}/skel", "**") : {
          path     = "/etc/skel/${fp}"
          encoding = "base64"
          content  = filebase64("${path.module}/skel/${fp}")
          append   = true
        }
      ]
    ])

    users  = local.users
    groups = local.groups

    runcmd = var.asdf == null ? [] : flatten([
      "git clone https://github.com/asdf-vm/asdf.git ${local.asdf.dir} --branch=${local.asdf.version}",
      [for p in coalescelist(local.asdf.plugins, []) : "${local.asdf.dir}/bin/asdf plugin-add ${p}"],
      "chgrp -R staff ${local.asdf.dir} ${local.asdf.data_dir}",
      "chmod -R g+rw ${local.asdf.dir}",
    ])
  }
}

