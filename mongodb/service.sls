{% from "mongodb/map.jinja" import mongodb with context %}
mongodb_service_running:
  service.running:
    - running: True
    - name: {{ mongodb.service_name }}
    - enable: True
    - init_delay: 10
