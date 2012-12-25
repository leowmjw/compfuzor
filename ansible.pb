---
- hosts: all
  user: rektide
  vars_files:
  - "vars/ansible.vars"
  tasks:
  - include: "tasks/xdg.vars.tasks"
  - name: insure CONFIG_DIR:$CONFIG_DIR exists
    file: path=$CONFIG_DIR state=directory
  - name: insure INSTALL_DIR:$INSTALL_DIR exists
    file: path=$INSTALL_DIR state=directory
  - name: insure BIN_DIR:$BIN_DIR exists
    file: path=$BIN_DIR state=directory
  #### default hosts file
  - name: copy DEFAULT_HOSTS:$DEFAULT_HOSTS into CONFIG_DIR:$CONFIG_DIR
    copy: src=files/ansible/$DEFAULT_HOSTS dest=$CONFIG_DIR/
  - name: check for existing ANSIBLE_HOSTS_FILE:$ANSIBLE_HOSTS_FILE
    shell: test -e $ANSIBLE_HOSTS_FILE && echo 1 || echo 0
    register: has_ansible_hosts_file
  - name: default symlink ANSIBLE_HOSTS_FILE:$ANSIBLE_HOSTS_FILE to DEFAULT_HOSTS:$DEFAULT_HOSTS
    file: src=$CONFIG_DIR/$DEFAULT_HOSTS dest=$ANSIBLE_HOSTS_FILE state=link
    when_integer: ${has_ansible_hosts_file.stdout} == 0
  #### env setter helper
  - name: check for existing CONFIG_DIR/ANSIBLE_ENV:$CONFIG_DIR/$ANSIBLE_ENV
    shell: test -e $CONFIG_DIR/$ANSIBLE_ENV && echo 1 || echo 0
    register: has_ansible_env
  - name: template ANSIBLE_ENV:$ANSIBLE_ENV into CONFIG_DIR:$CONFIG_DIR
    template: src=files/ansible/$ANSIBLE_ENV dest=$CONFIG_DIR/$ANSIBLE_ENV mode=0755
    when_integer: ${has_ansible_env.stdout} == 0
  #### link to install
  - name: check for existing CONFIG_DIR/INSTALL_LINK:$CONFIG_DIR/$INSTALL_LINK install link
    shell: test -e $CONFIG_DIR/$INSTALL_LINK && echo 0 || echo 1
    register: need_install_link
  - name: creating install link CONFIG_DIR/INSTALL_LINK:$CONFIG_DIR/$INSTALL_LINK to $INSTALL_DIR
    file: src=$INSTALL_DIR dest=$CONFIG_DIR/$INSTALL_LINK state=link
    when_integer: ${need_install_link.stdout} > 0 and ${has_xdg_config_dir.stdout} > 0
  #### xdg_config_dir/ansible install
  - name: check whether xdg_config_dir exists qand is different from CONFIG_DIR:$CONFIG_DIR
    shell: test "${has_xdg_config_dir.stdout}" == 1 -a "x${xdg_config_dir.stdout}" != "x$CONFIG_DIR" -a ! -e "${xdg_config_dir.stdout}/ansible" && echo 1 || echo 0
    register: need_config_link
  - name: create xdg_config_dir:${xdg_config_dir.stdout} link to $CONFIG_DIR
    file: src=$CONFIG_DIR dest=${xdg_config_dir.stdout}/ansible state=link
    when_integer: ${need_config_link.stdout} > 0
  - file: src=$CONFIG_DIR/$ANSIBLE_ENV dest=$BIN_DIR/$ANSIBLE_ENV state=link
  ### install git
  - name: git clone ansible repo
    git: repo=$ANSIBLE_GIT dest=$INSTALL_DIR