require 'hive/controller'
require 'hive/worker/tv'

module Hive
  class Controller
    # The TV controller
    class Tv < Controller
      def detect
        #hive_details = Hive.devicedb('Hive').find(Hive.id)
        #if hive_details.key?('devices')
        #  hive_details['devices'].select { |d| d['device_type'] == 'tv' }.collect do |device|
        #    Hive.logger.debug("Found TV #{device}")
        #    device['queues'] = device['device_queues'].collect do |queue_details|
        #      queue_details['name']
        #    end
        #    self.create_device(device)
        #  end
        #else
        #  raise DeviceDetectionFailed
        #end

        Hive.logger.debug("Checking Hive Mind")
        mm_device_list = Hive.hive_mind.device_details['connected_devices']
        Hive.logger.debug(mm_device_list)
        if mm_device_list.is_a? Array
          mm_device_list.select { |d| d['plugin_type'] == 'HiveMindTv::Plugin' }.collect do |device|
            Hive.logger.debug("Found TV: #{device.inspect}")
            self.create_device(device)
          end
        else
          []
        end
      end
    end
  end
end
