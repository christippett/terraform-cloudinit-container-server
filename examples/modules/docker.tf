module "docker" {
  source = "../../modules/docker"

  daemon_config = {
    debug   = true
    tls     = true,
    tlscert = "/var/docker/server.pem",
    tlskey  = "/var/docker/serverkey.pem",
    hosts   = ["tcp://192.168.59.3:2376"]
  }
}

output "docker" {
  value = {
    config    = module.docker.config
    user_data = module.docker.user_data
  }
}
