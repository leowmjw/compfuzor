---
- hosts: all
  sudo: True
  vars:
    TYPE: reprepro
    INSTANCE: main
    VAR_DIRS:
    - www/dists
    - www/pool
    - db
    - incoming
    - tmp/list
    - tmp/incoming
    DIRS:
    - .z
    FILES:
    - reprepro.env
    ETC_FILES:
    - distributions
    - options
    - incoming
    LINKS:
      dists: var/www/dists
      pool: var/www/pool
      .z/reprepro.env: reprepro.env
  vars_files:
  - vars/common.vars
  - private/reprepro.vars
  gather_facts: false
  tasks:
  - include: tasks/srv.vars.tasks
  - include: tasks/srv.tasks
  - template: src=files/reprepro/override dest=${ETC.stdout}/override-dsc.${item.codename}
    with_items: $REPOS
  - template: src=files/reprepro/override dest=${ETC.stdout}/override-deb.${item.codename}
    with_items: $REPOS
  - file: path=${VAR.stdout}/incoming/${item.codename} state=directory
    with_items: $REPOS
  - file: path=${VAR.stdout}/tmp/incoming/${item.codename} state=directory
    with_items: $REPOS
  # TODO: private/ keys install
  #- file: src=${DIR.stdout}/www dest=${WWW_LINKS_D}/*.*.archive state=link
- hosts: all
  sudo: True
  tags:
  - packages
  - root
  vars_files:
  - vars/common.vars
  tasks:
   - apt: pkg=reprepro state=$APT_INSTALL
     only_if: not $APT_BYPASS
 