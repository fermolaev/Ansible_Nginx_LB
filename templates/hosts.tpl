nginx:
  hosts:
%{ for idx, ip in nginx_ip ~}
    Nginx-${idx +1}:
      ansible_host: ${ip}
%{ endfor ~}
nginxlb:
  hosts:
    ${lb_ip}