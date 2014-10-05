(function($) {
  'use strict';

  function update_title($pnl, val) {
    var $h2     = $pnl.find('.panel-title a');
    var action = $h2.html()
                    .replace('...', '')
                    .replace(/<em>[^<]+<\/em>/, '');

    action += " <em>" + val + "</em>";

    $h2.html(action);
  }

  function next_panel($pnl) {
    var $next = $pnl.next();
    $next.removeClass('hidden');
    $next.find(".panel-title a").click();
    $next.find('input').focus();
  }

  function ready() {
    $('.panel-collapse').each(function() {
      var $pnl = $(this);
      if($pnl.hasClass('in')) {
        return;
      }

      $pnl.parents('.panel').addClass('hidden');
    });

    $('input[name=type]').on('click', function() {
      var $radio  = $(this);
      var $pnl    = $radio.parents('.panel');
      var val     = $radio.val();

      update_title($pnl, val);
      next_panel($pnl);

      $('span.verb').addClass('hidden');
      $('span.verb.verb-' + val).removeClass('hidden');
    });

    $('input[name=amount]').on('keyup', function() {
      var $input = $(this);
      var $pnl   = $input.parents('.panel');
      var val    = $input.val();

      update_title($pnl, "$" + val);
    });

    $('#transaction-amount button').on('click', function() {
      var $input = $(this);
      var $pnl   = $input.parents('.panel');
      next_panel($pnl);
    });
  }

  $(document).ready(ready);
  $(document).on('page:load', ready);

})(jQuery);
