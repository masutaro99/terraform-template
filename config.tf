terraform {
  backend "s3" {
    bucket = "tfstate-bucket-maskenpa" # 作成したS3バケット
    region = "ap-northeast-1"
    key = "terraform.tfstate"
    encrypt = true
  }
}