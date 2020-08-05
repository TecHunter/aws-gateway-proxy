variable "region" {
  default = "eu-central-1"
  type = string
}

variable "profile" {
  default = "default"
  type = string
}

variable "stage" {
  default = "prod"
  type = string
}

variable "base_url" {
  default = "https://registry.npmjs.org"
  type = string
}

variable "api_name" {
  type = string
}

variable "api_description" {
  type = string
}

variable "domain" {
  default = "techunter.io"
  type = string
}

variable "subdomain" {
  default = "proxy"
  type = string
}
