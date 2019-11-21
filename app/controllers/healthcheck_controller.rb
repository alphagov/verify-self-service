class HealthcheckController < ApplicationController
  skip_before_action :authenticate_user!, :set_user,
                     :configure_permitted_parameters,
                     :check_authorization

  def index
    checks = [
      Healthcheck::CognitoCheck,
      Healthcheck::DbCheck,
      Healthcheck::StorageCheck,
      Healthcheck::HubCheck,
    ]
    result = Healthcheck::Checker.new(checks).run

    render json: result, status: result[:status]
  end
end
