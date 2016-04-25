{% from "mongodb/map.jinja" import mongodb with context %}

add_mongodb_package_repository:
  pkgrepo.managed:
    - humanname: MongoDB 3.3 Repository
    - content: {{ mongodb.apt_repository }}
    - mirrorlist: deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.2 main
    - dist: jessie
    - keyid: {{ mongodb.mongo_key }}
    - keyserver: {{ mongodb.mongo_keyserver }}
    - require_in:
      - pkg: install_mongodb

install_mongodb:
  pkg.installed:
    - pkgs: {{ mongodb.pkgs }}
    - refresh: True

start_mongodb_service:
  service:
    - running
    - name: {{ mongodb.service }}
    - enable: True
    - require:
      - pkg: mongodb
