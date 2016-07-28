{% from "mongodb/map.jinja" import mongodb with context %}
{% set admin_pass = salt.pillar.get('mongodb:admin_password') %}
{% set admin_user = salt.pillar.get('mongodb:admin_username', 'admin') %}

{% for user in salt.pillar.get('mongodb:users', []) %}
{% set user_roles = user.get('roles', {}).get('add', []) %}
create_user_{{ user.name }}_on_{{ user.database }}:
  mongodb_user.present:
    - name: {{ user.name|trim }}
    - passwd: {{ user.password|trim }}
    - database: {{ user.database }}
    - user: {{ admin_user }}
    - password: {{ admin_pass|trim }}
    - authdb: admin
    - host: localhost
    - port: 27017

grant_roles_to_{{ user.name }}_on_{{ user.database }}:
  module.run:
    - name: mongodb.user_grant_roles
    - m_name: {{ user.name }}
    - roles: {{ user_roles }}
    - database: {{ user.database }}
    - user: {{ admin_user }}
    - password: {{ admin_pass }}
    - authdb: admin
    - host: localhost
    - port: 27017
{% endfor %}
