module DeviseHelper
  def devise_error_messages!
    return '' if resource.errors.empty?

    messages = resource
                  .errors
                  .full_messages
                  .map { |msg|
                    content_tag(:li, msg, class: 'list-group-item')
                  }
                  .join

    # title = I18n.t('errors.messages.not_saved',
    #   count: resource.errors.count,
    #   resource: resource.class.model_name.human.downcase)

    title = "Oops!  Having a little trouble here."
    html = <<-HTML
    <div class="alert alert-danger">
      <button type="button" class="close" data-dismiss="alert">x</button>
      <h4>#{ title }</h4>
      <ul class='list-group'>
        #{ messages }
      </ul>
    </div>
    HTML

    html.html_safe
  end
end
