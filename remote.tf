terraform {
    backend "S3" {
        bucket = "epsi-rlajeunesse"
        key = "/terraform_tfstate"
        region = "us-east-1"
    }
}