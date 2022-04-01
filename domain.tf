data "aws_route53_zone" "hostzone" {
  name = "masutaro99.com"
}

resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.hostzone.zone_id
  name    = "www.${data.aws_route53_zone.hostzone.name}"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

output "domain_name" {
  value = aws_route53_record.record.name
}