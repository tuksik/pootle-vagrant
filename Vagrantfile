# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = 'provision/playbook.yml'
    ansible.sudo = true
  end

  config.vm.network "forwarded_port", guest: 80, host: 8000
  config.vm.network "forwarded_port", guest: 443, host: 8043
  config.vm.network "forwarded_port", guest: 5432, host: 5433
  config.vm.network 'private_network', ip: '192.168.60.10'
  config.vm.hostname = 'test.mattermost.dev'

  config.vm.synced_folder "./vagrant", "/vagrant_data"

  config.vm.provider 'virtualbox' do |v|
      v.memory = 2048
      v.cpus = 2
      v.name = 'Mattermost Translation Server'
  end
end
