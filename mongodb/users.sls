{% from "mongodb/map.jinja" import mongodb with context %}
{% set admin_pass = salt.pillar.get('mongodb:admin_password') %}
{% set admin_user = salt.pillar.get('mongodb:admin_username', 'admin') %}

{% for user in salt.pillar.get('mongodb:users', []) %}
add_{{ user.name }}_user:
  mongodb_user.present:
    - name: {{ user.name }}
    - passwd: {{ user.password }}
    - database: {{ user.database }}
    - host: {{ mongodb.bind_ip }}
    - port: {{ mongodb.port }}
    - user: {{ admin_user }}
    - password: {{ admin_pass }}

{% if user.get('roles', {}).get('add') %}
assign_roles_to_{{ user.name }}:
  module.run:
    - name: mongodb.user_grant_roles
    - m_name: {{ user.name }}
    - roles: {{ user.roles.add }}
    - database: {{ user.database }}
    - host: {{ mongodb.bind_ip }}
    - port: {{ mongodb.port }}
    - user: {{ admin_user }}
    - password: {{ admin_pass }}
{% endif %}

{% if user.get('roles', {}).get('revoke') %}
revoke_roles_from_{{ user.name }}:
  module.run:
    - name: mongodb.user_revoke_roles
    - m_name: {{ user.name }}
    - roles: {{ user.roles.revoke }}
    - database: {{ user.database }}
    - host: {{ mongodb.bind_ip }}
    - port: {{ mongodb.port }}
    - user: {{ admin_user }}
    - password: {{ admin_pass }}
{% endif %}
{% endfor %}
