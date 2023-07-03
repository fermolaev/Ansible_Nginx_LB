%{ for idx, c in password ~}
${idx +1}: ${format("%s %s %s", fqdn, ip[idx], c)}
%{ endfor ~}
