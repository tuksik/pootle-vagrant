# Vagrant machine for Mattermost Pootle

This is a vagrant that will provision a working Pootle server with Mattermost translations

### Requirements
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/)
* [Ansible](http://docs.ansible.com/ansible/intro_installation.html)
* Clone this repository with `git clone git@github.com:enahum/pootle-vagrant.git`

### Run the vagrant machine
Once **VirtualBox**, **Vagrant** and **Ansible** are installed `cd` to the cloned repository directory and issue this command

```
$ vagrant up
```

Wait until it finishes the provisioning and you should be able to access through
[http://localhost:8000](http://localhost:8000) or from the same directory with `vagrant ssh`