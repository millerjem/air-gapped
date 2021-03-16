# AWS service endpoints

# EC2 endpoint
resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = "${aws_vpc.airgap_vpc.id}"
  service_name      = "com.amazonaws.${var.region_id}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.allow_all.id}",
  ]

  subnet_ids = [
    "${aws_subnet.private.id}"
  ]

  private_dns_enabled = true
}

resource "aws_route53_zone" "internal" {
  name         = "us-iso-east-1.c2s.ic.gov."
  vpc {
    vpc_id = "${aws_vpc.airgap_vpc.id}"
  }
}

resource "aws_route53_record" "ec2_record" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "ec2.${aws_route53_zone.internal.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${lookup(aws_vpc_endpoint.ec2.dns_entry[0], "dns_name")}"]
}

# ELB endpoint
resource "aws_vpc_endpoint" "elb" {
  vpc_id            = "${aws_vpc.airgap_vpc.id}"
  service_name      = "com.amazonaws.${var.region_id}.elasticloadbalancing"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.allow_all.id}",
  ]

  subnet_ids = [
    "${aws_subnet.private.id}"
  ]

  private_dns_enabled = true
}

# STS endpoint
resource "aws_vpc_endpoint" "sts" {
  vpc_id            = "${aws_vpc.airgap_vpc.id}"
  service_name      = "com.amazonaws.${var.region_id}.sts"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.allow_all.id}",
  ]

  subnet_ids = [
    "${aws_subnet.private.id}"
  ]

  private_dns_enabled = true
}

# S3 endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = "${aws_vpc.airgap_vpc.id}"
  service_name      = "com.amazonaws.${var.region_id}.s3"
}

#S3 endpoint routing table association
resource "aws_vpc_endpoint_route_table_association" "route_table_association" {
  route_table_id  = "${aws_route_table.airgap_vpc_region_private.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

