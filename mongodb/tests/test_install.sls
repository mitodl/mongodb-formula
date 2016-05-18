{% for package in salt.pillar.get('mongodb:install:pkgs') %}
test_installed_{{ package }}:
  testinfra.package:
    - name: {{ package }}
    - is_installed: True
{% endfor %}
