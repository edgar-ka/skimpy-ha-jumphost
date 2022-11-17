resource "aws_s3_bucket" "this_bucket" {
  bucket = local.bucket_name
  tags = {
    Name      = local.bucket_name
    Terraform = true
  }
}

resource "aws_s3_bucket_acl" "this_bucket_acl" {
  bucket = aws_s3_bucket.this_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "this_access_block" {
  bucket = aws_s3_bucket.this_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this_encription" {
  bucket = aws_s3_bucket.this_bucket.bucket

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}