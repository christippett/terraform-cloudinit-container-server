terraform {
  required_providers {
    cloudinit = {
      source = "hashicorp/cloudinit"
    }
  }
  experiments = [module_variable_optional_attrs]
}
