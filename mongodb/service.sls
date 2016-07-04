mongodb_service_running:
  service.running:
    - running: True
    - name: mongod
    - enable: True
    - init_delay: 10
