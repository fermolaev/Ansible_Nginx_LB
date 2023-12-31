#----------| Random pass for VM user |------------

resource "random_password" "vm_user" {
  count            = length(var.devs)
  length           = var.pass_length
  special          = true
  override_special = var.pass_strong
}

#----------| Digital Ocean Droplet + SSH |------------

data "digitalocean_ssh_key" "rebrain" {
  name = "REBRAIN.SSH.PUB.KEY"
}

resource "digitalocean_ssh_key" "myssh" {
  name       = "SSH Key Terraform 2"
  public_key = file(var.ssh_path)
}

resource "digitalocean_droplet" "vm" {
  count = length(var.devs)

  image    = var.os
  name     = var.devs[count.index]
  region   = var.region
  size     = var.vm_size
  ssh_keys = [data.digitalocean_ssh_key.rebrain.id, digitalocean_ssh_key.myssh.fingerprint]
  tags     = var.task_email

  #Подключение в создаваемой VM для установки пароля 
  connection {
    type        = var.connect_type
    host        = self.ipv4_address
    user        = var.vm_user
    private_key = file(var.ssh_privat)
    agent       = false
  }

  provisioner "file" {
    source      = var.ssh_privat
    destination = "/tmp/key.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.vm_user}:${random_password.vm_user[count.index].result} | chpasswd",
      "sed -i -e 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config",
      "systemctl restart ssh",
      "iptables -A INPUT -p tcp --dport 80 -j ACCEPT",
      "eval `ssh-agent -s` && chmod 400 /tmp/key.pem && ssh-add /tmp/key.pem",
    ]
  }
}

locals {
  do_ip_droplet = digitalocean_droplet.vm[*].ipv4_address
}

#----------| AWS 53 DNS |------------

data "aws_route53_zone" "rebrain" {
  name = var.zone_name
}

resource "aws_route53_record" "www" {
  count = length(var.devs)

  zone_id = data.aws_route53_zone.rebrain.zone_id
  name    = var.devs[count.index]
  type    = var.dns_type
  ttl     = var.ttl
  records = [local.do_ip_droplet[count.index]]
}

#----------| Ansible Files |------------

resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/templates/hosts.tpl", {
    nginx_ip = digitalocean_droplet.vm[*].ipv4_address
  })
  filename = "${path.module}/ansible/nginx/hosts.yaml"
}

#----------| Output STATS |------------

resource "local_file" "stats" {
  content = templatefile("${path.module}/templates/all_data.sh.tpl", {
    password = [for pass in random_password.vm_user[*] : pass.result]
    fqdn     = aws_route53_record.www[*].fqdn
    ip       = digitalocean_droplet.vm[*].ipv4_address
  })
  filename = "${path.module}/vm_info.txt"
}

locals {
  all_data = [for index, pass in [for pass in random_password.vm_user : nonsensitive(pass.result)] :
  "${index + 1}: ${format("%s %s %s", aws_route53_record.www[index].fqdn, digitalocean_droplet.vm[index].ipv4_address, pass)}"]
}

#--------------------------------------------------------
#
#               MY Ansible VPC
#
#--------------------------------------------------------

resource "digitalocean_droplet" "ansible" {
  depends_on = [digitalocean_droplet.vm]
  image      = "ubuntu-22-04-x64"
  name       = "ansible"
  region     = var.region
  size       = var.vm_size
  ssh_keys   = [digitalocean_ssh_key.myssh.fingerprint]
  tags       = var.task_email

  connection {
    type        = var.connect_type
    host        = self.ipv4_address
    user        = var.vm_user
    private_key = file(var.ssh_privat)
    agent       = false
  }

  provisioner "file" {
    source      = "${path.module}/ansible/nginx-instal.yml"
    destination = "/root/nginx-instal.yml"
  }

  provisioner "file" {
    source      = "${path.module}/ansible/nginx/hosts.yaml"
    destination = "/root/hosts.yaml"
  }

  provisioner "file" {
    source      = var.ssh_privat
    destination = "/tmp/key.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "apt install ansible -y ",
      "eval `ssh-agent -s`",
      "chmod 400 /tmp/key.pem",
      "ssh-add /tmp/key.pem",
      "ansible-playbook nginx-instal.yml -i /root/hosts.yaml  --ssh-common-args='-o StrictHostKeyChecking=no'",
    ]
  }
}

