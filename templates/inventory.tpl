%{ for index,addr in split(",", ip_addrs) ~}
${addr} %{ if length(rack_ids) > 0 }rack_id=AZ-${split(",", rack_ids)[index]}%{ endif }
%{ endfor ~}
