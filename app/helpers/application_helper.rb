module ApplicationHelper
  def format_date_time(cert_date_time)
    cert_date_time.strftime("%e-%m-%Y %H:%M")
  end

  def certificate_expiry(certificate)
    if certificate.not_after - Time.now < 30.day
      (certificate.not_after.to_date - Time.now.to_date).to_i.to_s
    end
  end
end
