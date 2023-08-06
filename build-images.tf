data "template_file" "nginx_load_balancer_config" {
  template = file("load-balancer-template.tpl")

  vars = {
    servers = join(",", [for i in range(var.server_count) : format("nginx-reverse-proxy-%d", i)])
  }
}

resource "local_file" "nginx_load_balancer_config" {
  content  = data.template_file.nginx_load_balancer_config.rendered
  filename = "nginx-load-balancer.conf"
}

resource "null_resource" "build_docker_images" {
  provisioner "local-exec" {
    command = "./build.sh"
  }

  triggers = {
    config_content = data.template_file.nginx_load_balancer_config.rendered
  }

  depends_on = [local_file.nginx_load_balancer_config]
}

resource "docker_image" "nginx_load_balancer" {
  name = "nginx-load-balancer:latest"
  depends_on = [null_resource.build_docker_images]
}

resource "docker_image" "nginx_reverse_proxy" {
  name = "nginx-reverse-proxy:latest"
  depends_on = [null_resource.build_docker_images]
}