module ErrorHelper
  def error_messages_for(model, name, specified_in_en_file: false)
    return unless model.errors.present?

    initialize_error_messages_for(model, name, specified_in_en_file)

    content_tag :div, error_div_govuk_summary_styles do
      (error_heading + error_body).html_safe
    end
  end

  def error_message_on(errors, field)
    return unless errors.present?

    message = errors.full_messages_for(field).first
    content_tag :span, id: 'value-error', class: 'govuk-error-message' do
      content_tag(:span, t('shared.errors.error'),
                  class: 'govuk-visually-hidden')
      t('shared.errors.message', message: message)
    end
  end

private

  def initialize_error_messages_for(model, name, specified_in_en_file)
    @name = name
    @model = model
    @errors = model.errors
    @specified_in_en_file = specified_in_en_file
  end

  def error_heading
    content_tag :h2, t('shared.errors.problem',
                       count: @errors.count,
                       model: @model.class.model_name.human.downcase),
                class: 'govuk-error-summary__title', id: 'error-summary-title'
  end

  def error_body
    content_tag :div, class: 'govuk-error-summary__body' do
      content_tag :ul, class: 'govuk-list govuk-error-summary__list' do
        @errors.each do |key|
          error_content_listitem(key)
        end
      end
    end
  end

  def error_content_listitem(key)
    concat(
      content_tag(
        :li,
        link_to(
          @errors.full_messages_for(key).first,
          locate_error_field(key)
        ),
        'data-turbolinks': 'false'
      )
    )
  end

  def locate_error_field(key)
    @specified_in_en_file ? "##{t(".#{key}")}" : "##{@name}_#{key}"
  end

  def error_div_govuk_summary_styles
    {
      class: 'govuk-error-summary', 'aria-labelledby': 'error-summary-title',
      role: 'alert', 'tab-index': '-1', 'data-module': 'error-summary'
    }
  end
end
