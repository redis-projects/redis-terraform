terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

data "aws_route53_zone" "parent" {
  name         = "${var.parent_zone}."
  private_zone = false
}

#resource "aws_route53_record" "A-records" {
#  zone_id = data.aws_route53_zone.parent.zone_id
#  name    = replace("node${count.index+1}.${var.cluster_fqdn}.", ".${data.aws_route53_zone.parent.name}", "")
#  type    = "A"
#  ttl     = "60"
#  records = [ tostring(var.ip_addresses[count.index]) ]
#  count   = length(var.ip_addresses)
#}

#resource "aws_route53_record" "NS-record" {
#  zone_id = data.aws_route53_zone.parent.zone_id
#  name    = replace("${var.cluster_fqdn}.", ".${data.aws_route53_zone.parent.name}", "")
#  type    = "NS"
#  ttl     = "60"
#  records = formatlist("%s.%s.",tolist(aws_route53_record.A-records.*.name),"${data.aws_route53_zone.parent.name}")
#}

resource "aws_route53_record" "NS-record" {
  zone_id = data.aws_route53_zone.parent.zone_id
  name    = replace("${var.cluster_fqdn}.", ".${data.aws_route53_zone.parent.name}", "")
  type    = "NS"
  ttl     = "60"
  records = split("%", var.dns_lb_name)
}
