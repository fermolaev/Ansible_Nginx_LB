---
Install Nginx + enable sites
This role install Nginx and enable sites.
---
Role Variables
    nginx_sites: (string) path of sites configs
    sites_link: (string) link to sites configs
    ports: (list/number) wich ports nginx will be  listen
---
How use:
ansible-galaxy init nginx_install
ansible-playbook role_nginx.yml --ssh-common-args='-o StrictHostKeyChecking=no'
