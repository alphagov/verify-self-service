module ApplicationHelper
  def format_date_time(cert_date_time)
    cert_date_time.strftime("%e-%m-%Y %H:%M")
  end

  def date_to_readable_long_format(cert_date_time)
    cert_date_time.strftime("%d %B %Y, %H:%M%P")
  end
end
