# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "en_US.UTF-8"

MACHINES = {
  :'system-boot' => {
    :box => 'generic/centos9s',
    :cpus => 1,
    :memory => 512
  }
}

current_dir = File.expand_path(File.dirname(__FILE__))

Vagrant.configure("2") do |config|
  MACHINES.each do |host_name, host_config|
    config.vm.define host_name do |host|
      host.vm.box = host_config[:box]
      host.vm.host_name = host_name.to_s

      host.vm.provider :virtualbox do |vb|
        vb.cpus = host_config[:cpus]
        vb.memory = host_config[:memory]

        vb.customize ['modifyvm', :id, '--uart1', '0x3F8', '4',
          '--uartmode1', 'server', current_dir + '/serial_socket']
      end

      host.vm.provision :shell do |shell|
        shell.path = 'provision.sh'
        shell.privileged = false
      end
    end
  end
end
