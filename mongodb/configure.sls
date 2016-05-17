{% from "mongodb/map.jinja" import mongodb with context %}

#TODO: Remove non-clustering flow for now - it just complicates things
{% if salt.pillar.get('mongodb:cluster:enabled') %}
copy_mongodb_key_file:
  file.managed:
    - name: {{ mongodb.cluster_key_file }}
    - contents: "{{ salt.pillar.get('mongodb:cluster:cluster_key') }}"
    - owner: mongodb
    - group: mongodb
    - mode: 0600
    - require:
      - pkg: install_packages
{% endif %}

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

#TODO: Wait for salt to start up again

#TODO: Create the super user

#TODO: Initialize the repset

#TODO: Create users from list of users
