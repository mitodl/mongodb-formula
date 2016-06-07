{% from "mongodb/map.jinja" import mongodb with context %}

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
    - name: /etc/mongodb.conf
    - template: jinja
    - source: salt://mongodb/templates/mongodb.conf.j2
    - require:
      - file: copy_mongodb_key_file
    - require_in:
      - service: mongodb_service_running
    - watch_in:
      - service: mongodb_service_running

wait_for_mongo:
  cmd.run:
    - name: |
        until [ `netstat -tunlp | grep {{ mongodb.port }} | wc -l` -ge 1 ]
        do
          sleep 1
        done
    - shell: /bin/bash
    - timeout: 60
    - require:
      - file: place_mongodb_config_file
      - service: mongodb_service_running

{% if 'mongodb_primary' in grains['roles'] %}

{% set replset_config = {'_id': salt['pillar.get']('mongodb:replset_name', 'rs0'), 'members': []} %}
{% if salt.pillar.get("mongodb:VAGRANT", false) %}
{% do replset_config['members'].append({'_id': 0, 'host': '192.168.33.10:' + mongodb.port}) %}
{% else %}
{% set member_id = 0 %}
{% for id, addrs in salt['mine.get']('roles:mongodb', 'network.get_hostname', expr_form='grain').items() %}
{% do replset_config['members'].append({'_id': member_id, 'host': id}) %}
{% set member_id = member_id + 1 %}
{% endfor %}
{% endif %}

{% set mongo_cmd = '/usr/bin/mongo --port ' + mongodb.port %}

initiate_replset:
  cmd.run:
    - name: >
        {{ mongo_cmd }} --eval "printjson(rs.initiate({{ replset_config }}))"
    - onlyif: "[ `{{ mongo_cmd }} --eval 'printjson(rs.status())' | grep -i 'errmsg' | wc -l` -eq 1 ]"
    - shell: /bin/bash
    - require:
        - cmd: wait_for_mongo

wait_for_initialization:
  cmd.run:
    - name: |
        until [ `{{ mongo_cmd }} --eval 'printjson(rs.config())' | grep -i initializing | wc -l` -eq 0 ]
        do
          sleep 1
        done
        sleep 20 # Add a brief extra wait for things to settle
    - shell: /bin/bash
    - timeout: 60
    - require:
        - cmd: initiate_replset

place_root_user_script:
  file.managed:
    - name: /tmp/create_root.js
    - source: salt://mongodb/templates/create_root.js.j2
    - template: jinja

execute_root_user_script:
  cmd.run:
    - name: {{ mongo_cmd }} /tmp/create_root.js
    - require:
      - file: place_root_user_script
      - cmd: wait_for_mongo

{% for user in salt.pillar.get('mongodb:users', {}) %}
add_{{ user.name }}_user:
  mongodb_user.present:
    - name: {{ user.name }}
    - passwd: {{ user.password }}
    - database: {{ user.database }}
    - user: {{ salt.pillar.get('mongodb:admin_username') }}
    - password: {{ salt.pillar.get('mongodb:admin_password') }}
    - host: localhost
    - port: {{ mongodb.port }}
    - require:
      - cmd: execute_root_user_script
{% endfor %}

place_repset_script:
  file.managed:
    - name: /tmp/repset_init.js
    - source: salt://mongodb/templates/repset_init.js.j2
    - onlyif: "[ `{{ mongo_cmd }} --eval 'printjson(rs.status())' | grep -i 'errmsg' | wc -l` -eq 1 ]"
    - template: jinja

execute_repset_script:
  cmd.run:
    - name: {{ mongo_cmd }} /tmp/repset_init.js
    - require:
      - file: place_repset_script
      - cmd: wait_for_mongo
      - cmd: execute_root_user_script
{% endif %}
