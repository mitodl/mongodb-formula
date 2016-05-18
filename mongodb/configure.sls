{% from "mongodb/map.jinja" import mongodb with context %}

#DOING: Remove non-clustering flow for now - it just complicates things
copy_mongodb_key_file:
  file.managed:
    - name: {{ mongodb.cluster_key_file }}
    - contents: "{{ salt.pillar.get('mongodb:cluster_key') }}"
    - owner: mongodb
    - group: mongodb
    - mode: 0600
    - require:
      - pkg: install_packages

stop_mongodb_service:
  service.dead:
    - running: True
    - name: mongodb
    - enable: True
    - require:
      - pkg: install_packages

place_mongodb_config_file:
  file.managed:
    - name: /etc/mongod.conf
    - template: jinja
    - source: salt://mongodb/templates/mongod.conf.j2
    - watch_in:
      - service: stop_mongodb_service
      - service: start_mongodb_service

#DOING: Wait for salt to start up again
wait_for_mongo:
  cmd.run:
    - name: |
        until [ `netstat -tunlp | grep {{ mongodb.port }} | wc -l` -eq 1 ]
        do
          sleep 1
        done
    - shell: /bin/bash
    - timeout: 60
    - require:
      - file: place_mongodb_config_file

#DOING: Create the super user
add_admin_user:
  mongodb_user.present:
    - name: {{ salt.pillar.get('mongodb:admin_username') }}
    - passwd: {{ salt.pillar.get('mongodb:admin_password') }}
    - database: admin
    - host: localhost
    - port: {{ mongodb.port }}
    - require:
      - pkg: install_packages
      - file: place_mongodb_config_file
      - cmd: wait_for_mongo

#TODO: Initialize the repset

#DOING: Create users from list of user
{% for user in salt.pillar.get('mongodb:users', {}) %}
add_admin_user:
  mongodb_user.present:
    - name: {{ user.user }}
    - passwd: {{ user.password }}
    - database: {{ user.database }}
    - host: localhost
    - port: {{ mongodb.port }}
    - require:
      - pkg: install_packages
      - file: place_mongodb_config_file
      - cmd: wait_for_mongo
{% endfor %}
