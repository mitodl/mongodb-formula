{% from "mongodb/map.jinja" import mongodb with context %}
{% from "mongodb/map.jinja" import vagrant_host with context %}

include:
  - .service

copy_mongodb_key_file:
  file.managed:
    - name: {{ mongodb.cluster_key_file }}
    - contents: "{{ salt.pillar.get('mongodb:cluster_key') }}"
    - owner: mongodb
    - group: mongodb
    - mode: 0600

place_mongodb_config_file:
  file.managed:
    - name: /etc/mongod.conf
    - template: jinja
    - source: salt://mongodb/templates/mongodb.conf.j2
    - require:
      - file: copy_mongodb_key_file
    - watch_in:
      - service: mongodb_service_running

{% if 'mongodb_primary' in grains['roles'] %}

{% set replset_config = {'_id': salt.pillar.get('mongodb:replset_name', 'rs0'), 'members': []} %}
{% if salt.pillar.get("mongodb:VAGRANT", false) %}
{% do replset_config['members'].append({'_id': 0, 'host': vagrant_host + ':' + mongodb.port}) %}
{% else %}
{% set member_id = 0 %}
{% set eth0_index = 0 %}
{% for id, addrs in salt.mine.get('G@roles:mongodb and G@environment:{0}'.format(salt.grains.get('environment')), 'network.ip_addrs', expr_form='compound').items() %}
{% do replset_config['members'].append({'_id': member_id, 'host': addrs[eth0_index] }) %}
{% set member_id = member_id + 1 %}
{% endfor %}
{% endif %}

{% set MONGO_ADMIN_USER = salt.pillar.get("mongodb:admin_username") %}
{% set MONGO_ADMIN_PASSWORD = salt.pillar.get("mongodb:admin_password") %}
{% set mongo_cmd = '/usr/bin/mongo --port {0}'.format(mongodb.port) %}

place_root_user_script:
  file.managed:
    - name: /tmp/create_root.js
    - source: salt://mongodb/templates/create_root.js.j2
    - template: jinja
    - context:
        MONGO_ADMIN_USER: {{ MONGO_ADMIN_USER }}
        MONGO_ADMIN_PASSWORD: {{ MONGO_ADMIN_PASSWORD }}

execute_root_user_script:
  cmd.run:
    - name: {{ mongo_cmd }} /tmp/create_root.js
    - require:
      - file: place_root_user_script
      - cmd: wait_for_mongo
    - require:
        - service: mongodb_service_running
    - require_in:
        - file: configure_keyfile_and_replicaset

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
    - require_in:
        - file: configure_keyfile_and_replicaset
{% endfor %}

initiate_replset:
  cmd.run:
    - name: >-
        {{ mongo_cmd }} --username {{ MONGO_ADMIN_USER|trim }}
        --password {{ MONGO_ADMIN_PASSWORD|trim }} --authenticationDatabase admin
        --eval "printjson(rs.initiate({{ replset_config }}))"
    - onlyif: >-
        {{ mongo_cmd }} --username {{ MONGO_ADMIN_USER|trim }}
        --password {{ MONGO_ADMIN_PASSWORD|trim }} --authenticationDatabase admin
        --eval 'printjson(rs.status())' | grep -i 'errmsg' | test -n
    - shell: /bin/bash
    - require:
        - cmd: execute_root_user_script
        - file: configure_keyfile_and_replicaset
        - service: mongodb_service_running

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

configure_keyfile_and_replicaset:
  file.append:
    - name: /etc/mongod.conf
    - text: |
        keyFile = {{ mongodb.cluster_key_file }}
        replSet = {{ salt['pillar.get']('mongodb:replset_name', 'rs0') }}
    - watch_in:
        - service: mongodb_service_running
