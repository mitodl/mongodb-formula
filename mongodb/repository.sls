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
    - name: dirnmgr
    - refresh: True
{% endif %}

add_mongodb_package_repository:
  pkgrepo.managed:
    - humanname: MongoDB Repository
    {% if os_family == 'Debian' %}
    - name: {{ mongodb.repo }}
    {% elif os_family == 'RedHat' %}
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
{% endif %}
