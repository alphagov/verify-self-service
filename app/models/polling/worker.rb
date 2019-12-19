class Worker
  def after_commit(model)
    poll(environment: model.environment)
  end

  def poll(
    scheduler: Polling::Scheduler.new,
    status_updater: CERT_STATUS_UPDATER,
    hub_api: HUB_CONFIG_API,
    environment:
  )
    certificates = Component.all_pollable_certificates(environment)
    certificates.each { |certificate|
      scheduler.mode(:every)
               .perform(-> { status_updater.update_hub_usage_status_for_cert(hub_api, certificate) })
               .until(scheduler.action_result&.certificate&.in_use_at.present?)
    }
  end

  def self.poll
    Worker.new
  end
end
