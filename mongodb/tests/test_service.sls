test_mongod_service_running:
  testinfra.service:
    - name: mongod
    - is_running: True
    - is_enabled: True
