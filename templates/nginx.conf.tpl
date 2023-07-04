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
      listen 443 ssl;
      server_name fermolaev.devops.rebrain.srwx.net;
      
      ssl on;
      ssl_certificate /etc/nginx/ssl/fullchain_fermolaev.devops.rebrain.srwx.net; 
      ssl_certificate_key /etc/nginx/ssl/fermolaev.devops.rebrain.srwx.net.key;


      location / {
          include proxy_params;
          
          proxy_pass http://app;
          proxy_redirect off;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
      }
   }
}