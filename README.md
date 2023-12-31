# Nginx + Terraform + Docker, load balancing and reverse proxied

I created this project to experiment with Terraform's capabilities and see what I could come up with. This is free for anyone to use and learn from. I've outlined what files do what below, explaining the process.

## Contents

### .gitignore

Tells git CLI that I do not want to include certain files. In particular, I am avoiding including Terraform local files. The way that Terraform works is it is stateful based on local files it generates. Using the command `terraform apply` created files that may have secrets or other sensitive data we do not want to share.

This file derives from [https://github.com/github/gitignore](https://github.com/github/gitignore) as I am not 100% familiar with what I should or should not include with Terraform.

### .terraform.lock.hcl

Ensures that Terraform grabs images that match the images I used to build this initially. This was generated by running `terraform init`. You can possibly upgrade these with `terraform init -upgrade`.

### *.tf

#### build-images.tf

This is where we are creating the `nginx-load-balancer.conf` with the `load-balancer-template.tpl`. We must do this as we need to insert the hostnames into an array within the nginx configuration. This allows nginx to know the hostnames for lookup via Docker DNS. Docker IPs should not be relied upon as they constantly change on container creation.

As well, the docker image creation and build processes have dependencies to ensure race conditions are not hit when creating the load balancer config. An extra barrier is also added in the `build.sh` as a last resort stop gap.

#### create-containers.tf

This file is sort of our "main" Terraform file. This is where the provider of docker is defined and configured. You will then also see a docker network created, and our two container definitions. The reverse proxy containers are iterated using the `count` key, which reads from the `var.server_count` variable.

When iteration occurs, you can use the `count.index` value as needed. In this case, I use it to iterate the port and define an environment variable for each host that represents that container's name. This is later used in `index.html` as part of `entrypoint.sh`.

#### variables.tf

A single default variable of `server_count` is defined here. The default value is 3 which means 3 reverse proxies will be created. You can adjust this at time of execute using `terraform apply -var "server_count=4"` for example.

### build.sh

Builds our two Dockerfile* into images for spawning our containers. It has retry logic for `nginx-load-balancer.conf` as I faced race conditions a few times. Otherwise, it's fairly simple and just copies some files to the name `nginx.conf` and then deletes on completion.

### Dockerfile*

#### Dockerfile-load-balancer

Nothing to note here really, this is about as cut and try of a Dockerfile as you can get. We are using nginx alpine for a lightweight instance and copying in a configuration file.

### Dockerfile-reverse-proxy

First we copy in `index.html`, then `entrypoint.sh`, then `nginx.conf`, chmod to add executable flag to `entrypoint.sh`, and run `entrypoint.sh`.

### entrypoint.sh

We are doing a simple `sed -i` which does an inline replace of `PROXY_ID_PLACEHOLDER` with environment variable `$PROXY_ID` in our `index.html`. Doing this at runtime simplifies a few things for us. After that, we just run `nginx` in non-daemon mode. This is important as we are in a container. This ensures nginx stays in the foreground.

### index.html

A very basic webpage for displaying the hostname of what proxy we hit. I added this as a way to test without having an actual reverse proxied host or software to access.

### load-balancer-template.tpl

This is a template configuration we use to generate `nginx-load-balancer.conf`. Given we do not have a static number of hosts which we will reverse proxy, this generates said list at execution time based on the passed variable from `build-images.tf`

### nginx-reverse-proxy.conf

A very basic nginx configuration with additional /status page which hits our `index.html`