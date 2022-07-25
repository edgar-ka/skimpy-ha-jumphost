resource "aws_s3_bucket" "this_bucket" {
  bucket = local.bucket_name
  acl    = "private"
  tags = {
    Name      = local.bucket_name
    Terraform = true
  }
}
