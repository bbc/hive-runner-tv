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
          mm_device_list.select { |d| d['device_type'] == 'Tv' }.collect do |device|
            Hive.logger.debug("Found TV: #{device.inspect}")
            mm_devices << self.create_device(device)
          end
        else
          mm_devices = []
        end
        Hive.logger.debug("Devices: #{mm_devices}")

        hive_details = Hive.devicedb('Hive').find(Hive.id)
        if hive_details.key?('devices')
          hive_details['devices'].select { |d| d['device_type'] == 'tv' }.collect do |device|
            Hive.logger.debug("Found TV #{device}")
            device['queues'] = device['device_queues'].collect do |queue_details|
              queue_details['name']
            end
            self.create_device(device)
          end
        else
          raise DeviceDetectionFailed
        end
      end
    end
  end
end
