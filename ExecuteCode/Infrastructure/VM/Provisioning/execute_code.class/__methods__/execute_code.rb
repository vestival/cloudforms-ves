

#
#            Automate Method
#

begin
  require 'net/ssh'

  @method = 'SC-execute_ssh'
  $evm.log("info", "#{@method} - EVM Automate Method Started")

  # Dump all of root's attributes to the log
  $evm.root.attributes.sort.each { |k, v| $evm.log("info", "#{@method} Root:<$evm.root> Attribute - #{k}: #{v}")}

  # Grab the VM object
  $evm.log(:info, "vmdb_object_type: #{$evm.root['vmdb_object_type']}")
  case $evm.root['vmdb_object_type']
  when 'miq_provision'
    vm   = $evm.root['miq_provision'].destination
  else
    vm = $evm.root['vm']
  end
  raise 'VM object is empty' if vm.nil?
  
  unless vm.vendor.downcase == 'vmware'
    $evm.log(:warn, "Only VMware supported currently, exiting gracefully")
    exit MIQ_OK
  end

  if vm.ipaddresses.length.zero?
  $evm.log(:info, "#{vm.name} doesnt have an IP address yet - retrying in 1 minute")
  vm.ext_management_system.refresh
  $evm.root['ae_result'] = 'retry'
  $evm.root['ae_retry_interval'] = '1.minute'
  exit MIQ_OK
  end
  
  output    = ""
  username  = "root"
  password  = "temporal"
  ip = vm.ipaddresses[0]
  $evm.log("info", "These are the variables Victor Host = #{ip}, username =  #{username} password = #{password}")

  command   = "rm -f /etc/sysconfig/rhn/systemid; rhnreg_ks --username jmanso --password registroclientes; yum install -y /sbin/mount.nfs screen; service rpcbind start; service rpc.idmapd start; service portmap start; mkdir /mnt/cfme; mount -t nfs 172.20.22.220:/var/www/html/pub /mnt/cfme; /mnt/cfme/software/deploy.sh"
  $evm.log("info","Executing command: #{command}")

  begin
    Net::SSH.start("#{ip}", "#{username}", :password => "#{password}") do |ssh|
      output = ssh.exec!(command)
    end
  rescue => err
    $evm.log("error","[#{err}]\n#{err.backtrace.join("\n")}")
  end
  $evm.log("info", "Output from SSH: #{output}")

  #
  # Exit method
  #
  $evm.log("info", "#{@method} - EVM Automate Method Ended")
  exit MIQ_OK

  #
  # Set Ruby rescue behavior
  #
rescue => err
  $evm.log("error", "#{@method} - [#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
