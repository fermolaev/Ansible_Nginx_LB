#------------|Prefix Uaer Car|---------------

variable "devs" {
  type    = list(string)
  default = ["fermolaev-dev", "fermolaev=db", "fermolaev-prod"]
}

#------------| Digital Ocean Token|---------------s
variable "do_token" {
  description = "API токе к DO"
  type        = string
  sensitive   = true
}

#------------| Digital Ocean Droplet|---------------
variable "os" {
  description = "Что за ось будет"
  type        = string
  default     = "ubuntu-18-04-x64"
}

variable "vm_size" {
  description = "Ресурсы создаваемой тачки"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "task_email" {
  description = "обязательно ввиде task_name:terraform-03 user_email:ihlin_ilia_at_gmail.com "
  type        = list(string)
}

variable "region" {
  description = "Регион создаваемой тачки"
  type        = string
  default     = "fra1"
}

#------------| Change user password|---------------

variable "vm_user" {
  description = "Логин пользователя VM"
  type        = string
  sensitive   = true
  default     = "root"
}

variable "connect_type" {
  description = "Вид подключения к VM для удаленных команд"
  type        = string
  default     = "ssh"
}

variable "pass_length" {
  description = "Длина пароля"
  type        = number
  default     = 8
}

variable "pass_strong" {
  #Не используем *[]^${}\?|()
  description = "Спец символы для пароля"
  type        = string
  default     = "#%+-._~"
}

#------------| SSH Keys|---------------
variable "ssh" {
  description = "Мой ssh ключ к создаваймой тачке"
  type        = string
  sensitive   = true
}

variable "ssh_path" {
  description = "Путь до моего ssh ключа"
  type        = string
}

variable "ssh_privat" {
  description = "Путь до моего приватного ssh ключа"
  type        = string
  sensitive   = true
}
