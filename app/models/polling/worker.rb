class Worker
  def after_commit(model)
    certificates = Component.all_pollable_certificates(model.environment)
    certificates.each do |certificate|
      SCHEDULER.mode(:every)
               .perform(-> { CERT_STATUS_UPDATER.update_hub_usage_status_for_cert(HUB_CONFIG_API, certificate) })
               .until(SCHEDULER.action_result&.certificate&.in_use_at.present?)
    end
  end

  def self.poll
    Worker.new
  end
end
