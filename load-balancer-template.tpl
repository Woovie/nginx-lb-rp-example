events {}

http {
    upstream backend_servers {
        %{~ for server in split(",", servers) ~}
        server ${server}:80;
        %{~ endfor ~}
    }

    server {
        listen 80;

        location / {
            proxy_pass http://backend_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}