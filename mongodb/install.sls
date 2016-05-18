{% from "mongodb/map.jinja" import mongodb with context %}

include:
  - .service
  - .configure


{% if mongodb.install_pkgrepo %}
add_mongodb_package_repository:
  pkgrepo.managed:
    - name: {{ mongodb.repo }}
    - humanname: MongoDB Repository
    {% if mongodb.get('repo') %}
    - dist: {{ mongodb.repo_dist }}
    {% endif %}
    - keyid: {{ mongodb.key }}
    - keyserver: {{ mongodb.keyserver }}
    - refresh_db: True
{% endif %}

install_packages:
  pkg.installed:
    - pkgs: {{ mongodb.pkgs }}
    - refresh: True
    - install_recommends: True
    - require:
      - pkgrepo: add_mongodb_package_repository
    - require_in:
      - service: mongodb_service_running
      - file: copy_mongodb_key_file
      - service: mongodb_service_running

{% for egg in mongodb.pip_pkgs %}
install_{{ egg }}_pip_package:
  pip.installed:
    - name: {{ egg }}
{% endfor %}
