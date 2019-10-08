module ApplicationHelper
  PAGE_TITLE_SUFFIX = ' - GOV.UK Verify Manage Certificates'.freeze

  def format_date_time(cert_date_time)
    cert_date_time.strftime("%e-%m-%Y %H:%M")
  end

  def date_to_readable_long_format(cert_date_time)
    cert_date_time.strftime("%d %B %Y, %H:%M%P")
  end

  def page_title(title)
    content_for :page_title, title + PAGE_TITLE_SUFFIX
  end

  def display_page_title
    title = content_for :page_title
    raise NotImplementedError.new('Missing page title') if Rails.env.test? && (title == PAGE_TITLE_SUFFIX || title.nil?)

    title
  end
end
