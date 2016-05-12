start_mongodb_service:
  service.running:
    - running: True
    - name: mongod
    - enable: True
    - require:
      - pkg: install_packages
