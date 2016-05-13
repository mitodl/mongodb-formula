{% for package_obj in salt.pillar.get('mongodb:install:pkgs') %}
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
