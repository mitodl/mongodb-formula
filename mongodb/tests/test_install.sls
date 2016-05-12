{% from "mongodb/map.jinja" import mongodb with context %}

{% for package_obj in mongodb.pkgs %}
{% for package, version in package_obj.items() %}
test_installed_{{ package }}:
  testinfra.package:
    - name: {{ package }}
    - is_installed: True
    - version:
        parameter: {{ version }}
        expected: True
        comparison: eq
{% endfor %}
{% endfor %}
