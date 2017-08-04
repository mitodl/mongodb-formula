{% from "mongodb/map.jinja" import mongodb with context %}

include:
  - .service

{% set MONGO_ADMIN_USER = salt.pillar.get("mongodb:admin_username") %}
{% set MONGO_ADMIN_PASSWORD = salt.pillar.get("mongodb:admin_password") %}
{% set mongo_cmd = '/usr/bin/mongo --port {0}'.format(mongodb.port) %}
{% set mongodb_cluster_key = salt.pillar.get('mongodb:cluster_key') %}

place_mongodb_config_file:
  file.managed:
    - name: /etc/{{ mongodb.service_name }}.conf
    - template: jinja
    - source: salt://mongodb/templates/mongodb.conf.j2
    - watch_in:
      - service: mongodb_service_running

place_root_user_script:
  file.managed:
    - name: /tmp/create_root.js
    - source: salt://mongodb/templates/create_root.js.j2
    - template: jinja
    - context:
        MONGO_ADMIN_USER: {{ MONGO_ADMIN_USER }}
        MONGO_ADMIN_PASSWORD: {{ MONGO_ADMIN_PASSWORD }}

{% if (mongodb_cluster_key and 'mongodb_primary' in grains['roles'])
   or not (mongodb_cluster_key) %}
execute_root_user_script:
  cmd.run:
    - name: {{ mongo_cmd }} /tmp/create_root.js
    - require:
      - file: place_root_user_script
      - service: mongodb_service_running
{% endif %}

{% for user in salt.pillar.get('mongodb:users', {}) %}
add_{{ user.name }}_user_to_{{ user.database }}:
  mongodb_user.present:
    - name: {{ user.name }}
    - passwd: {{ user.password }}
    - database: {{ user.database }}
    - host: localhost
    - port: {{ mongodb.port }}
    - require:
      - file: place_mongodb_config_file
      - cmd: execute_root_user_script
{% endfor %}

{% if mongodb_cluster_key %}
copy_mongodb_key_file:
  file.managed:
    - name: {{ mongodb.cluster_key_file }}
    - contents_pillar: 'mongodb:cluster_key'
    - owner: mongodb
    - group: mongodb
    - mode: 0600
    - require:
      - file: place_mongodb_config_file
    - require_in:
        - file: configure_keyfile_and_replicaset
{% endif %}

{% if 'mongodb_primary' in grains['roles'] %}
{% set replset_config = salt.pillar.get('mongodb:replset_config') %}

initiate_replset:
  cmd.run:
    - name: >-
        {{ mongo_cmd }} --username {{ MONGO_ADMIN_USER|trim }}
        --password='{{ MONGO_ADMIN_PASSWORD|trim }}' --authenticationDatabase admin
        --eval "printjson(rs.initiate({{ replset_config }}))"
    - onlyif: >-
        {{ mongo_cmd }} --username {{ MONGO_ADMIN_USER|trim }}
        --password='{{ MONGO_ADMIN_PASSWORD|trim }}' --authenticationDatabase admin
        --eval 'printjson(rs.status())' | grep -i 'errmsg' | test -n
    - shell: /bin/bash
    - require:
        - cmd: execute_root_user_script
        - service: configure_keyfile_and_replicaset

wait_for_initialization:
  cmd.run:
    - name: |
        until [ `{{ mongo_cmd }} --username {{ MONGO_ADMIN_USER|trim }} \
        --password {{ MONGO_ADMIN_PASSWORD|trim }} --authenticationDatabase admin \
        --eval 'printjson(rs.config())' | grep -i initializing | wc -l` -eq 0 ]
        do
          sleep 1
        done
        sleep 5 # Add a brief extra wait for things to settle
    - shell: /bin/bash
    - timeout: 60
    - require:
        - cmd: initiate_replset
{% endif %}

{% if mongodb_cluster_key %}
configure_keyfile_and_replicaset:
  file.append:
    - name: /etc/{{ mongodb.service_name }}.conf
    - text: |
        keyFile = {{ mongodb.cluster_key_file }}
        replSet = {{ salt['pillar.get']('mongodb:replset_name', 'rs0') }}
  service.running:
    - name: {{ mongodb.service_name }}
    - init_delay: 10
    - watch:
        - file: configure_keyfile_and_replicaset
{% endif %}
