module "aws-dev" {
  source           = "../../infra"
  instance         = "t2.micro"
  region_aws       = "us-east-1"
  chave            = "iac-dev"
  grupoDeSeguranca = "Desenvolvimento"
  minimo           = 0
  maximo           = 1
  asgroup        = "Dev"
  producao         = false
}

