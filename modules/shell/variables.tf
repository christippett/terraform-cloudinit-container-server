variable "users" {
  description = "Configures a list of users."

  type = map(object({
    groups  = optional(list(string))
    homedir = optional(string)
    shell   = optional(string)
    sudo    = optional(string)
    uid     = optional(number)

    # expiredate          = optional(string)
    # gecos               = optional(string)
    # inactive            = optional(number)
    # lock_passwd         = optional(bool)
    # no_log_init         = optional(bool)
    # no_user_group       = optional(bool)
    # no_create_home      = optional(bool)
    # passwd              = optional(string)
    # primary_group       = optional(string)
    # selinux_user        = optional(string)
    # snapuser            = optional(string)
    ssh_authorized_keys = optional(list(string))
    # ssh_import_id       = optional(string)
    # ssh_redirect_user   = optional(bool)
    # system              = optional(bool)

  }))
}

variable "asdf" {
  description = ""
  nullable    = true

  type = object({
    version  = optional(string)
    dir      = optional(string)
    data_dir = optional(string)
    plugins  = list(string)
  })
}

variable "apt" {
  description = ""
  nullable    = true

  type = object({
    packages = list(string)
  })

  default = {
    packages = [
      "autoconf",
      "automake",
      "build-essential",
      "curl",
      "dirmngr",
      "fish",
      "git",
      "gpg",
      "libbz2-dev",
      "libffi-dev",
      "liblzma-dev",
      "libncurses5-dev",
      "libreadline-dev",
      "libsqlite3-dev",
      "libssl-dev",
      "libtool",
      "libxml2-dev",
      "libxmlsec1-dev",
      "llvm",
      "make",
      "unzip",
      "wget",
      "xz-utils",
      "zlib1g-dev",
      "zsh"
    ]
  }
}
