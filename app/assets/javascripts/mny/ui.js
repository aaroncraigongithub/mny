/**
 * UI stuff
 */

(function($) {
  function ready() {
    window.setTimeout(function() {
      $('.alert-info').fadeOut();
    }, 5000);

    $('a[data-target=#transaction-list]').on('click', function() {
      var $el = $(this).find('i');
      if ($el.hasClass('fa-chevron-down')) {
        $el.addClass('fa-chevron-up');
        $el.removeClass('fa-chevron-down');
      }
      else {
        $el.addClass('fa-chevron-down');
        $el.removeClass('fa-chevron-up');
      }
    });
  }

  $(document).ready(ready);
  $(document).on('page:load', ready);
})(jQuery);
