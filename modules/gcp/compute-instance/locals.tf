locals {
  docker_compose_content = var.docker_compose_content != "" ? trimspace(var.docker_compose_content) : trimspace(templatefile("${path.module}/templates/docker-compose.yml.tpl", {
    app_port = var.app_upstream_port
  }))

  nginx_site_content = trimspace(templatefile("${path.module}/templates/nginx-site.conf.tpl", {
    web_domain = var.web_domain
    app_port   = var.app_upstream_port
  }))

  cloud_init = var.enable_web_stack ? templatefile("${path.module}/templates/cloud-init.yaml.tpl", {
    web_domain             = var.web_domain
    certbot_email          = var.certbot_email
    docker_compose_content = local.docker_compose_content
    nginx_site_content     = local.nginx_site_content
  }) : ""

  instance_metadata = merge(
    var.ssh_pubkey != "" ? { "ssh-keys" = "${var.ssh_user}:${var.ssh_pubkey}" } : {},
    var.enable_web_stack ? { "user-data" = local.cloud_init } : {},
  )
}
