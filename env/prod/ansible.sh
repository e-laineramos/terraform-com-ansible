#!bin/bash
cd /home/ubuntu
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python3 get-pip.py
sudo python3 -m pip install ansible
tee -a playbook.yml > /dev/null << EOT
- hosts: localhost
  tasks:
    - name: Instalando o Python3, virtualenv
      apt: 
        pkg:
          - python3
          - virtualenv
        update_cache: yes
      become: yes
    - name: Git clone
      ansible.builtin.git:
        repo: https://github.com/alura-cursos/clientes-leo-api.git
        dest: /home/ubuntu/novo-dir
        force: yes
        version: master
    - name: Instalando depedencias com pip (Django e Django rest)
      pip: 
        virtualenv: /home/ubuntu/novo-dir/venv
        requirements: /home/ubuntu/novo-dir/requirements.txt
    - name: Verificando se o projeto ja existe
      stat: 
        path: /home/ubuntu/novo-dir/setup/settings.py
      register: projeto
    - name: Iniciando o projeto
      shell: '. /home/ubuntu/novo-dir/venv/bin/activate; django-admin startproject setup /home/ubuntu/'
      when: not projeto.stat.exists
    - name: Alterando o hosts do settings
      lineinfile: 
        path: /home/ubuntu/novo-dir/setup/settings.py
        regexp: 'ALLOWED_HOSTS'
        line: 'ALLOWED_HOSTS = ["*"]'
        backrefs: yes
    - name: Configurando o banco de dados
      shell: '. /home/ubuntu/novo-dir/venv/bin/activate; python /home/ubuntu/novo-dir/manage.py migrate'
    - name: Carregando dados
      shell: '. /home/ubuntu/novo-dir/venv/bin/activate; python /home/ubuntu/novo-dir/manage.py loaddata clientes.json'
    - name: Iniciando o servidor
      shell: '. /home/ubuntu/novo-dir/venv/bin/activate; nohup python /home/ubuntu/novo-dir/manage.py runserver 0.0.0.0:8000 &'
EOT
ansible-playbook playbook.yml