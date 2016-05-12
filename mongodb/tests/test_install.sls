test_install_erlang_solutions_repository:
  testinfra.package:
    - name: mongodb-org
    - is_installed: True
