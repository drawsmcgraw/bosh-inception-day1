# Create a Concourse security group
resource "aws_security_group" "concourse-sg" {
  name        = "concourse-sg"
  description = "Concourse security group"
  vpc_id      = "${module.vpc.aws_vpc_id}"
  tags {
  Name = "concourse-sg"
  component = "concourse"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound connections from ELB
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = ["${aws_security_group.elb-sg.id}"]
  }

  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    security_groups = ["${aws_security_group.elb-sg.id}"]
  }
}

# Create an ELB security group
resource "aws_security_group" "elb-sg" {
  name        = "elb-sg"
  description = "ELB security group"
  vpc_id      = "${module.vpc.aws_vpc_id}"
  tags {
  Name = "elb-sg"
  component = "concourse"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound https
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound https
  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Create a new load balancer
resource "aws_elb" "concourse" {
  name = "concourse-elb"
  subnets = ["${module.vpc.bastion_subnet}"]
  security_groups = ["${aws_security_group.elb-sg.id}"]

  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  listener {
    instance_port = 2222
    instance_protocol = "tcp"
    lb_port = 2222
    lb_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 10
    timeout = 5
    target = "tcp:8080"
    interval = 30
  }

  tags {
  component = "concourse"
  }
}

output "elb_dns_name" {
  value = "${aws_elb.concourse.dns_name}"
}
