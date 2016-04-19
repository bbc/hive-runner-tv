require 'hive/controller'
require 'hive/worker/tv'

module Hive
  class Controller
    # The TV controller
    class Tv < Controller
      def detect
        Hive.logger.debug("Checking Hive Mind")
        mm_device_list = Hive.hive_mind.device_details['connected_devices']
        Hive.logger.debug("Device list: #{mm_device_list}")
        mm_devices = []
        if mm_device_list.is_a? Array
          #mm_device_list.select { |d| d['device_type'] == 'Tv' && d['status'] == 'happy' }.collect do |device|
          mm_device_list.select { |d| d['device_type'] == 'Tv' }.collect do |device|
            Hive.logger.debug("Found TV: #{device.inspect}")
            mm_devices << self.create_device(device)
          end
        else
          mm_devices = []
        end
        Hive.logger.debug("Devices: #{mm_devices}")
        mm_devices
      end
    end
  end
end
