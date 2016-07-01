require 'hive/controller'
require 'hive/worker/tv'

module Hive
  class Controller
    # The TV controller
    class Tv < Controller
      @@exclusion = []

      def self.add_exclusion ex
        @@exclusion << ex
      end

      def detect
        Hive.logger.debug("Checking Hive Mind")
        device_list = Hive.hive_mind.device_details['connected_devices']
        Hive.logger.debug("Device list: #{device_list}")
        devices = []
        if device_list.is_a? Array
          device_list.select { |d| valid? d }.collect do |device|
            Hive.logger.debug("Found TV: #{device.inspect}")
            devices << self.create_device(device)
          end
        else
          raise Hive::Controller::DeviceDetectionFailed
        end
        Hive.logger.debug("Devices: #{devices}")
        devices
      end

      private
      def valid? device
        if device['device_type'] == 'Tv'
          @@exclusion.each do |ex|
            match = true
            ex.each_pair do |key, value|
              match = match && device[key.to_s] != value
            end
            return false if ! match
          end
          return true
        else
          false
        end
      end
    end
  end
end
