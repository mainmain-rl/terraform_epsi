terraform {
    backend "s3" {
        bucket = "tsunamirr-rlajeunesse"
        key = "terraform_tfstate"
        region = "us-east-1"
    }
}