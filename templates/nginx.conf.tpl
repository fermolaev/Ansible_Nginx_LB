user www-data;
worker_processes {{ ansible_processor_vcpus }};
pid /run/nginx.pid;
error_log  /var/log/nginx/{{ ansible_hostname }}-error.log;

events {
  worker_connections 768;
  # multi_accept on;
}

http {
   upstream app{
 %{ for ip in nginx_ip ~}
    server ${ip};
%{ endfor ~}
   }

   server {
      listen 80;
      
      server_name fermolaev.devops.rebrain.srwx.net;

      location / {
          include proxy_params;
          
          proxy_pass http://app;
          proxy_redirect off;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
      }
   }
