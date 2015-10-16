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
          tries = [
            [ :launch_titantv ],
            [ :power_cycle, :launch_titantv ],
            [ :power_on, :launch_titantv ]
          ]

          tries.each do |commands|
            catch :commands_failed do
              commands.each do |command|
                throw :commands_failed if ! @device_api.run_sequence(command)
              end
              timeout = Time.now + 600
              while Time.now < timeout
                if @device_api.status == 'idle'
                  return self.pass('Titan TV launched')
                end
                sleep 5
              end
            end
          end

          self.fail("Failed to recover device")
        end
      end
    end
  end
end
