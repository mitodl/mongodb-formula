configure_log_rotation:
  file.managed:
    - name: /etc/logrotate.d/mongodb
    - source: salt://mongodb/templates/logrotate_config.j2
    - template: jinja
    - mode: '0644'
    - context:
        name: /var/log/mongodb.log
        options:
          - rotate 4
          - weekly
          - copytruncate
          - notifempty
          - compress
          - delaycompress
