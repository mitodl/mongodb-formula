{% from "mongodb/map.jinja" import mongodb with context %}

{% if salt.pillar.get('mongodb:cluster:enabled') %}
test_copy_mongodb_key_file:
  testinfra.file:
    - name: {{ mongodb.mongo_cluster_key_file }}
    - exists: True
    - contains:
        parameter: "{{ salt.pillar.get('mongodb:cluster:cluster_key') }}"
        expected: True
        comparison: is_
    - user:
        parameter: mongodb
        expected: True
        comparison: eq
    - group:
        parameter: mongodb
        expected: True
        comparison: eq
    - mode:
        parameter: 384
        expected: True
        comparison: eq
{% endif %}
