start_mongodb_service:
  service.start:
    - running: True
    - name: mongodb
    - enable: True
    - require:
      - pkg: install_packages
