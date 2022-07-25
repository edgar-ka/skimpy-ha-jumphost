output "bastion_host_name" {
  value = "${var.instance_dns_name}.${var.dns_zone}"
}

output "random_part" {
  value = random_pet.nikname.id
}

output "bucket_name" {
  value = aws_s3_bucket.this_bucket.id
}