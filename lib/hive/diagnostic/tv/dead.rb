require 'hive/diagnostic'

module Hive
  class Diagnostic
    class Tv
      class Dead < Diagnostic
        def diagnose
          status = @device_api.status
          case status
          when 'idle'
            self.pass('Device is idle')
          else
            self.fail("Device is #{status}")
          end
        end

        def repair(result)
          if @device_api.run_sequence(:launch_titantv)
            # TODO need retries instead of just a single long sleep
            sleep 30
            case @device_api.status
            when 'idle'
              self.pass('Titan TV launched')
            else
              self.fail('Unable to launch Titan TV')
            end
          else
            self.fail('Unable to launch Titan TV')
          end
        end
      end
    end
  end
end
