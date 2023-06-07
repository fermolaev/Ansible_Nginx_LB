This role install Nginx and enable sites.

Role Variables
1. nginx_sites: (string) path of sites configs
1. sites_link: (string) link to sites configs
1. ports: (list/number) wich ports nginx will be  listen

How use:
1. ansible-galaxy init nginx_install
1. ansible-playbook role_nginx.yml --ssh-common-args='-o StrictHostKeyChecking=no'
