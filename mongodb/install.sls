{% from "mongodb/map.jinja" import mongodb with context %}

add_mongodb_package_repository:
  pkgrepo.managed:
    - name: {{ salt.pillar.get('mongodb:install:repo') }}
    - humanname: MongoDB 2.6.5 Repository
    - dist: {{ salt.pillar.get('mongodb:install:repo_dist') }}
    - keyid: {{ salt.pillar.get('mongodb:install:key') }}
    - keyserver: {{ salt.pillar.get('mongodb:install:keyserver') }}
    - refresh_db: True

install_packages:
  pkg.installed:
    - pkgs: {{ salt.pillar.get('mongodb:install:pkgs') }}
    - refresh: True
    - install_recommends: True
    - require:
      - pkgrepo: add_mongodb_package_repository
