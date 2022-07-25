variable "project_name" {
  type    = string
  default = "ha-vpn"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_search" {
  type = map(object({ ami_owner = string, ami_filter = string }))
  default = {
    "t2.micro" = {
      ami_owner  = "amazon"
      ami_filter = "amzn-ami-hvm*"
    }
    "t3.micro" = {
      ami_owner  = "amazon"
      ami_filter = "amzn-ami-hvm*"
    }
    "t4g.nano" = {
      ami_owner  = "679593333241"
      ami_filter = "debian-10-arm64*"
    }
    "t4g.micro" = {
      ami_owner  = "679593333241"
      ami_filter = "debian-10-arm64*"
    }
    "t4g.small" = {
      ami_owner  = "679593333241"
      ami_filter = "debian-10-arm64*"
    }
  }
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.10.0.0/16"
}

variable "dns_zone" {
  type    = string
  default = "example.com"
}

variable "instance_dns_name" {
  type    = string
  default = "vpn"
}

variable "pub_key_path" {
  type = string
  default = "~/.ssh/id_rsa.pub"
}