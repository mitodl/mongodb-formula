{% from "mongodb/map.jinja" import mongodb with context %}

{% if salt.pillar.get('mongodb:cluster:enabled') %}
copy_mongodb_key_file:
  file.managed:
    - name: {{ mongodb.mongo_cluster_key_file }}
    - contents: "{{ salt.pillar.get('mongodb:cluster:cluster_key') }}"
    - owner: mongodb
    - group: mongodb
    - mode: 0600
    - require:
      - pkg: install_packages
{% endif %}
