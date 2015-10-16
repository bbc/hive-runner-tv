require 'hive/diagnostic'

module Hive
  class Diagnostic
    class Tv
      class Uptime < Diagnostic
        def initialize(config, options)
          @next_reboot_time = Time.now + config[:reboot_timeout] if config.has_key?(:reboot_timeout)
          super(config, options)
        end

        def diagnose
          if config.has_key?(:reboot_timeout)
            if Time.now < @next_reboot_time
              self.pass("Time to next reboot: #{@next_reboot_time - Time.now}s")
            else
              self.fail("Reboot required")
            end
          else
            self.pass("Not configured to reboot")
          end
        end

        def repair(result)
          @next_reboot_time += config[:reboot_timeout]
          @device_api.power_cycle ? self.pass("Successful reboot") : self.fail("Reboot failed")
        end
      end
    end
  end
end
