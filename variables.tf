variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Local do grupo de recursos"
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "student-rg"
  description = "Prefixo para o grupo de recursos que vai ser combinado com um nome randomico."
}

variable "username" {
  type        = string
  description = "O usuario que vai ser usado pra acessar a VM."
  default     = "azureuser"
}

variable "admin_passwd" {
    type = string
}
