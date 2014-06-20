module ForecastHelper
  def prep_scheduled_table(rows)
    rows.each do |row|
      row[:date] = link_to row[:date], edit_scheduled_transaction_path(row[:instance])
    end
  end
end
