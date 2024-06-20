module "aws-prod" {
  source           = "../../infra"
  instance         = "t2.micro"
  region_aws       = "us-east-1"
  chave            = "iac-prod"
  grupoDeSeguranca = "Producao"
  minimo           = 1
  maximo           = 10
  asgroup          = "Prod"
  producao         = true
}

