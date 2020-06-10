{% from "mongodb/map.jinja" import mongodb with context %}

include:
  - .repository

install_packages:
  pkg.installed:
    - pkgs: {{ mongodb.pkgs }}
    - refresh: True
    - install_recommends: True
    - skip_verify: True
    - require_in:
      - service: mongodb_service_running

install_pip_package:
  pip.installed:
    - pkgs: {{ mongodb.pip_pkgs }}
    - reload_modules: True
