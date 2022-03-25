##------------------------------------------------------------------------------
# Locals
##------------------------------------------------------------------------------

locals {
  website_bucket_name     = var.website_domain_name
  www_website_bucket_name = "www.${var.website_domain_name}"
}

#------------------------------------------------------------------------------
# S3 Bucket for logs
#------------------------------------------------------------------------------
resource "aws_s3_bucket" "log_bucket" {
    bucket = "${var.name_prefix}-log-bucket"
  tags = merge({
    Name = "${var.name_prefix}-logs"
  }, var.tags)
}

resource "aws_s3_bucket_acl" "log_bucket" {
    bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_versioning" "log_bucket" {
   bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status     = var.log_bucket_versioning_status
    mfa_delete = var.log_bucket_versioning_mfa_delete
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "log_bucket_access_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = data.aws_iam_policy_document.log_bucket_access_policy.json
}

data "aws_iam_policy_document" "log_bucket_access_policy" {
    statement {
          sid = "Allow access to logs bucket to current account"
          
    principals{
      type = "AWS"
      identifiers = ["arn:aws:iam::023557935063:root"]
    } 
    
    actions = [
      "s3:ListBucket*",
      "s3:GetObject",
    ]

    resources = [
      aws_s3_bucket.log_bucket.arn,
      "${aws_s3_bucket.log_bucket.arn}/*",
    ]
  }
}
#------------------------------------------------------------------------------
# Route53 Hosted Zone
#------------------------------------------------------------------------------
resource "aws_route53_zone" "hosted_zone" {
   count = var.create_route53_hosted_zone ? 1 : 0

  name = var.website_domain_name
  tags = merge({
    Name = "${var.name_prefix}-hosted-zone"
  }, var.tags)
}

#------------------------------------------------------------------------------
# ACM Certificate
#------------------------------------------------------------------------------
resource "aws_acm_certificate" "cert" {

  provider = aws.acm_provider
  
 # count = var.create_acm_certificate ? 1 : 0

  domain_name               = "*.${var.website_domain_name}"
  subject_alternative_names = [var.website_domain_name]

  validation_method = "EMAIL"

  tags = merge({
    Name = var.website_domain_name
  }, var.tags)

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_acm_certificate_validation" "cert_validation" {
    
  provider = aws.acm_provider
  certificate_arn         = aws_acm_certificate.cert.arn

}
