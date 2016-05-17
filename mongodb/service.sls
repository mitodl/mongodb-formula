start_mongodb_service:
  service.running:
    - running: True
    - name: mongodb
    - enable: True
    - require:
      - pkg: install_packages
