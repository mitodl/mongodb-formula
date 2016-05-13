test_mongod_service_running:
  testinfra.service:
    - name: mongodb
    - is_running: True
    - is_enabled: True
