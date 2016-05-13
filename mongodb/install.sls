{% from "mongodb/map.jinja" import mongodb with context %}

add_mongodb_package_repository:
  pkgrepo.managed:
    - name: {{ mongodb.repo }}
    - humanname: MongoDB 2.6.5 Repository
    - dist: {{ mongodb.repo_dist }}
    - keyid: {{ mongodb.key }}
    - keyserver: {{ mongodb.keyserver }}
    - refresh_db: True

install_packages:
  pkg.installed:
    - pkgs: {{ mongodb.pkgs }}
    - refresh: True
    - install_recommends: True
    - require:
      - pkgrepo: add_mongodb_package_repository
