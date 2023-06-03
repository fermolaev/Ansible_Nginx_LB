[nginx]
%{ for ip in nginx_ip ~}
${ip}
%{ endfor ~}