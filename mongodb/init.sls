{% from "mongodb/map.jinja" import mongodb with context %}

mongodb:
  pkg.installed:
    - pkgs: {{ mongodb.pkgs }}
  service:
    - running
    - name: {{ mongodb.service }}
    - enable: True
    - require:
      - pkg: mongodb
