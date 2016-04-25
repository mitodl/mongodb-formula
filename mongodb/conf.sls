{% from "mongodb/map.jinja" import mongodb, mongodb_config with context %}

include:
  - mongodb

mongodb-config:
  file.managed:
    - name: {{ mongodb.conf_file }}
    - source: salt://mongodb/templates/conf.jinja
    - template: jinja
    - context:
      config: {{ mongodb_config }}
    - watch_in:
      - service: mongodb
    - require:
      - pkg: mongodb
