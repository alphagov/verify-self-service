module Healthcheck
  class DbCheck
    def name
      :database_connectivity
    end

    def status
      ::ActiveRecord::Base.connection
      OK
    end
  end
end
