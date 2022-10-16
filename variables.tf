variable "project_name" {
  type        = string
  default     = "ha-vpn"
  description = "Some common prefix"
}

variable "region" {
  type        = string
  default     = "us-west-2"
  description = "Region you'll pretend to work from"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type. Refer to ami_search, add your own if necessary."
}

variable "ami_search" {
  type        = map(object({ ami_owner = string, ami_filter = string }))
  description = "Mappings for selected instance types to narrow AMI search"
  default = {
    "t2.micro" = {
      ami_owner  = "099720109477"
      ami_filter = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server*"
    }
    "t3.micro" = {
      ami_owner  = "099720109477"
      ami_filter = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server*"
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
  type        = string
  default     = "10.10.0.0/16"
  description = "CIDR block for newly-created VPC"
}

variable "dns_zone" {
  type        = string
  default     = "example.com"
  description = "DNS zone to manipulate. Must be hosted in your Route53"
}

variable "instance_dns_name" {
  type        = string
  default     = "vpn"
  description = "Instance DNS record within your zone"
}

variable "pub_key_path" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = "Public key to provision to the instance"
}