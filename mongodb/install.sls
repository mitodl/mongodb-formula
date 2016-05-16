{% from "mongodb/map.jinja" import mongodb with context %}

add_mongodb_package_repository:
  pkgrepo.managed:
    - name: {{ mongodb.install.repo }}
    - humanname: MongoDB 2.6.5 Repository
    - dist: {{ mongodb.install.repo_dist }}
    - keyid: {{ mongodb.install.key }}
    - keyserver: {{ mongodb.install.keyserver }}
    - refresh_db: True

install_packages:
  pkg.installed:
    - pkgs: {{ mongodb.install.pkgs }}
    - refresh: True
    - install_recommends: True
    - require:
      - pkgrepo: add_mongodb_package_repository
