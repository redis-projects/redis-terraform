%{ for addr in split(",", ip_addrs) ~}
${addr} rack_id=${rack_id}
%{ endfor ~}
