{% from "mongodb/map.jinja" import mongodb with context %}

{% for package in mongodb.pkgs.items() %}
test_installed_{{ package }}:
  testinfra.package:
    - name: {{ package }}
    - is_installed: True
{% endfor %}
