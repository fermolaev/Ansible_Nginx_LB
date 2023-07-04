#----------| Random pass for VM user |------------

resource "random_password" "vm_user" {
  count            = length(var.devs)
  length           = var.pass_length
  special          = true
  override_special = var.pass_strong
}

#----------| Digital Ocean Droplet Data |------------

data "digitalocean_ssh_key" "rebrain" {
  name = "REBRAIN.SSH.PUB.KEY"
}

data "digitalocean_ssh_key" "myssh" {
  name = "SSH Key Terraform 2"
}

#----------| Nginx Load Balancer |------------

resource "digitalocean_droplet" "lb" {
  image    = var.os
  name     = "lb"
  region   = var.region
  size     = var.vm_size
  ssh_keys = [data.digitalocean_ssh_key.rebrain.id, data.digitalocean_ssh_key.myssh.id]
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
      "iptables -A INPUT -p tcp --dport 80 -j ACCEPT",
      "eval `ssh-agent -s` && chmod 400 /tmp/key.pem && ssh-add /tmp/key.pem",
    ]
  }
}

#----------| Web Servers |------------

resource "digitalocean_droplet" "vm" {
  depends_on = [digitalocean_droplet.lb]
  count      = length(var.devs)
  image      = var.os
  name       = var.devs[count.index]
  region     = var.region
  size       = var.vm_size
  ssh_keys   = [data.digitalocean_ssh_key.rebrain.id, data.digitalocean_ssh_key.myssh.id]
  tags       = var.task_email

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
      "sudo sed -i -e 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config",
      "systemctl restart ssh",
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
  zone_id = data.aws_route53_zone.rebrain.zone_id
  name    = "fermolaev"
  type    = var.dns_type
  ttl     = var.ttl
  records = [digitalocean_droplet.lb.ipv4_address]
}

#----------| Ansible Files |------------

resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/templates/hosts.tpl", {
    nginx_ip = digitalocean_droplet.vm[*].ipv4_address
    lb_ip    = digitalocean_droplet.lb.ipv4_address
  })
  filename = "${path.module}/ansible/hosts.yaml"
}

resource "local_file" "nginx_lb_conf" {
  content = templatefile("${path.module}/templates/nginx.conf.tpl", {
    nginx_ip = digitalocean_droplet.vm[*].ipv4_address
  })
  filename = "${path.module}/ansible/nginx_load_balancer/templates/nginx.conf.j2"
}

#----------| Output STATS |------------

resource "local_file" "stats" {
  content = templatefile("${path.module}/templates/all_data.sh.tpl", {
    password = [for pass in random_password.vm_user[*] : pass.result]
    fqdn     = aws_route53_record.www.fqdn
    ip       = digitalocean_droplet.vm[*].ipv4_address
  })
  filename = "${path.module}/vm_info.txt"
}

locals {
  all_data = [for index, pass in [for pass in random_password.vm_user : nonsensitive(pass.result)] :
  "${index + 1}: ${format("%s %s %s", aws_route53_record.www.fqdn, digitalocean_droplet.vm[index].ipv4_address, pass)}"]
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
  ssh_keys   = [data.digitalocean_ssh_key.myssh.id]
  tags       = var.task_email

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
      "apt install ansible -y ",
      "ansible-galaxy init nginx_install",
      "ansible-galaxy init nginx_load_balancer",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/ansible/"
    destination = "/root"
  }

  provisioner "remote-exec" {
    inline = [
      "eval `ssh-agent -s` && chmod 400 /tmp/key.pem && ssh-add /tmp/key.pem",
      "ansible-playbook role_nginx.yml -i hosts.yaml  --ssh-common-args='-o StrictHostKeyChecking=no'",
      "ansible-playbook nginxlb.yml -i hosts.yaml  --ssh-common-args='-o StrictHostKeyChecking=no'",
    ]
  }
}

#"ansible-playbook role_nginx.yml -i hosts.yaml  --ssh-common-args='-o StrictHostKeyChecking=no'",
#"ansible-playbook nginxlb.yml -i hosts.yaml  --ssh-common-args='-o StrictHostKeyChecking=no'",
# echo -n "123" |  ansible-vault encrypt ./nginx_install/var/main.yml
