module WorkHouse
  class SystemInfo
    def self.processor_count
      case RbConfig::CONFIG['host_os']
      when /darwin9/
        `hwprefs cpu_count`.to_i
      when /darwin/
        ((`which hwprefs` != '') ? `hwprefs thread_count` : `sysctl -n hw.ncpu`).to_i
      when /linux/
        `cat /proc/cpuinfo | grep processor | wc -l`.to_i
      when /freebsd/
        `sysctl -n hw.ncpu`.to_i
      when /mswin|mingw/
        require 'win32ole'
        wmi = WIN32OLE.connect("winmgmts://")
        cpu = wmi.ExecQuery("select NumberOfCores from Win32_Processor") # TODO count hyper-threaded in this
        cpu.to_enum.first.NumberOfCores
      end
    end
  end
end
