class VmLibrary < ActiveRecord::Base
  has_many :permissions, :dependent => :destroy, :order => "id ASC"

  has_many :vms, :dependent => :nullify, :order => "id ASC"
  belongs_to :hardware_pool
  has_one :quota, :dependent => :destroy



  def self.list_for_user(user)
    find(:all, :include => "permissions", 
         :conditions => "permissions.user='#{user}' and permissions.privilege='#{Permission::ADMIN}'")
  end

  def can_monitor(user)
    has_privilege(user, Permission::MONITOR)
  end
  def can_delegate(user)
    has_privilege(user, Permission::DELEGATE)
  end
  def is_admin(user)
    has_privilege(user, Permission::ADMIN)
  end

  def total_resources
    the_quota = quota
    if the_quota.nil?
      pool = hardware_pool
      while not(pool.nil?)
        if pool.quota
          the_quota = pool.quota
          pool = nil
        else
          pool = pool.superpool
        end
      end
    end
    if the_quota.nil?
      Quota.get_resource_hash(nil, nil, nil, nil, nil)
    else
      the_quota.total_resources
    end
  end

  def allocated_resources(exclude_vm = nil)
    pending_cpus = 0
    pending_memory = 0
    pending_nics = 0
    pending_vms = 0
    current_cpus = 0
    current_memory = 0
    current_nics = 0
    current_vms = 0
    storage = 0
    self.vms.each do |vm|
      unless (exclude_vm and exclude_vm.id == vm.id)
        if vm.consuming_resources?
          current_cpus += vm.num_vcpus_allocated
          current_memory += vm.memory_allocated
          # one vNIC per VM for now
          current_nics += 1
          current_vms += 1
        end
        if vm.pending_resource_consumption?
          pending_cpus += vm.num_vcpus_allocated
          pending_memory += vm.memory_allocated
          # one vNIC per VM for now
          pending_nics += 1
          pending_vms += 1
        end
        vm.storage_volumes.each do |volume|
          storage += volume.size
        end
      end
    end
    return { :current => Quota.get_resource_hash(current_cpus, current_memory, current_nics, current_vms, storage),
             :pending => Quota.get_resource_hash(pending_cpus, pending_memory, pending_nics, pending_vms, storage)}
  end

  def full_resources(exclude_vm = nil)
    total = total_resources
    allocated = allocated_resources(exclude_vm)
    available = {}
    available[:current] = Quota.subtract_resource_hash(total, allocated[:current])
    available[:pending] = Quota.subtract_resource_hash(total, allocated[:pending])
    labels = [["CPUs", :cpus, ""], 
              ["Memory", :memory_in_mb, "(mb)"], 
              ["NICs", :nics, ""], 
              ["VMs", :vms, ""], 
              ["Disk", :storage_in_gb, "(gb)"]]
    return {:total => total, :allocated => allocated, :available => available,
            :labels => labels}
  end

  def available_resources(exclude_vm = nil)
    return full_resources(exclude_vm)[:available]
  end

  # these resource checks are made at VM start/restore time
  # use pending here by default since this is used for queueing VM
  # creation/start operations
  #taskomatic should set use_pending_values to false
  def available_resources_for_vm(vm = nil, use_pending_values=true)
    if use_pending_values
      resources = full_resources(vm)[:available][:pending]
    else
      resources = full_resources(vm)[:available][:current]
    end
    # creation is limited to total quota value or values from largest host
    memhost = Host.find(:first, :order => "memory DESC",
                        :conditions => "hardware_pool_id = #{hardware_pool.id}")
    host_mem_limit = (memhost.nil? ? 0 : memhost.memory)
    cpuhost = Host.find(:first, :order => "num_cpus DESC",
                        :conditions => "hardware_pool_id = #{hardware_pool.id}")
    host_cpu_limit = cpuhost.nil? ? 0 : cpuhost.num_cpus
    resources[:memory] = host_mem_limit if resources[:memory].nil? or host_mem_limit < resources[:memory]
    resources[:cpus] = host_cpu_limit if resources[:cpus].nil? or host_cpu_limit < resources[:cpus]
    # update mb/gb values
    return Quota.get_resource_hash(resources[:cpus], resources[:memory], 
                             resources[:nics], resources[:vms], 
                             resources[:storage])
  end

  # these resource checks are made at VM create time
  def max_resources_for_vm(vm = nil)
    # use pending here since this is used for VM creation/start
    tot_resources = full_resources(vm)
    resources = tot_resources[:total]
    available = tot_resources[:available][:pending]
    # storage is enforced at creation
    resources[:storage] = available[:storage]

    # creation is limited to total quota value. Don't limit to largest
    # host at this point as new hosts may be added before starting VM

    # update mb/gb values
    return Quota.get_resource_hash(resources[:cpus], resources[:memory], 
                             resources[:nics], resources[:vms], 
                             resources[:storage])
  end
  def has_privilege(user, privilege)
    # check vm_library permissions first
    if (permissions.find(:first, 
                         :conditions => "permissions.privilege = '#{privilege}' and permissions.user = '#{user}'"))
      return true
    else
      # now check HW pool permissions
      return hardware_pool.has_privilege(user, privilege)
    end
  end
end