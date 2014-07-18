require 'mny/transaction_set'
require 'mny/report'
require 'mny/forecast'
require 'mny/qif'

module Mny

  # Display the given cents as a formatted string in the given currency.
  # Only works with 'usd' at the moment.
  def self.display_cents(amount, currency = 'usd')
    sprintf('$%5.02f', amount.to_f / 100.0)
  end

end
