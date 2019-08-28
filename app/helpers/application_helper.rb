module ApplicationHelper
  def format_date_time(cert_date_time)
    cert_date_time.strftime("%e-%m-%Y %H:%M")
  end

  def date_to_readable_long_format(cert_date_time)
    cert_date_time.strftime("%d %B %Y, %H:%M%P")

  def certificate_expiry(certificate)
    if certificate.not_after - Time.now < 30.day
      (certificate.not_after.to_date - Time.now.to_date).to_i.to_s
    end
  end
end
