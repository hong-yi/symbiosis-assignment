terraform {
    backend "s3" {
      bucket = "symbiosis-tfstate"
      key = "tfstate"
      region = "ap-southeast-1"
    }
}