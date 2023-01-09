# bucket
resource "aws_s3_bucket" "rke2-public" {
  bucket        = "${local.prefix}-${local.suffix}-public"
  force_destroy = true
}

# acl
resource "aws_s3_bucket_acl" "rke2-public" {
  bucket = aws_s3_bucket.rke2-public.id
  acl    = "public-read"
}

# versioning
resource "aws_s3_bucket_versioning" "rke2-public" {
  bucket = aws_s3_bucket.rke2-public.id
  versioning_configuration {
    status = "Enabled"
  }
}

# access policy
resource "aws_s3_bucket_policy" "rke2-public" {
  bucket = aws_s3_bucket.rke2-public.id
  policy = data.aws_iam_policy_document.rke2-s3-public.json
}

# public access policy
resource "aws_s3_bucket_public_access_block" "rke2-public" {
  bucket                  = aws_s3_bucket.rke2-public.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
