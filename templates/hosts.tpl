nginx:
  hosts:
%{ for ip in nginx_ip ~}
    ${ip}
%{ endfor ~}