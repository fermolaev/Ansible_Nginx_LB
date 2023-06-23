output "output-test-map-of-lists" {
  value = compact(local.all_data)
}

output "ansible_vm" {
  value = digitalocean_droplet.ansible.ipv4_address
}

