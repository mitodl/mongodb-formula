{% from "mongodb/map.jinja" import mongodb with context %}
{% set os_family = grains['os_family'] %}

{% if os_family == 'RedHat' %}
install_mongodb_gpg_key:
  cmd.run:
    - name: rpm --import {{ mongodb.gpg_key }}
    - require_in:
      - pkgrepo: add_mongodb_package_repository
{% endif %}

{% if mongodb.install_pkgrepo %}

{% if os_family == 'Debian' %}
ensure_dirmngr_is_installed:
  pkg.installed:
    - name: dirmngr
    - refresh: True
{% endif %}

{% if os_family == 'RedHat' %}
add_mongodb_package_repository:
  pkgrepo.managed:
    - humanname: MongoDB Repository
    - name: {{ mongodb.repo }}
    - name: MongoDB Repository
    - baseurl: {{ mongodb.repo }}
    - gpgcheck: 1
    - enabled: 1
    {% endif %}
    - keyid: {{ mongodb.key }}
    - keyserver: {{ mongodb.keyserver }}
    - refresh_db: True
    - require_in:
      - install_packages

{% elif os_family == 'Debian' %}
add_mongodb_pgp_key:
  cmd.run:
  - name: wget -qO - https://www.mongodb.org/static/pgp/server-{{ mongodb.version }}.asc | sudo apt-key add -
  - require_in:
      - install_packages

run_apt_update:
  cmd.run:
    - name: apt-get update
{% endif %}
