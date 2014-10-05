class ForecastController < ApplicationController
  before_action :load_scheduled
  before_action :load_forecast, only: [:forecast]

  def index
  end

  def forecast
  end

  private

  def load_scheduled
    @scheduled_transactions = []
    current_user.scheduled_transactions.each do |st|
      @scheduled_transactions<< {
        id: st.id,
        account:  st.account.name,
        date:     st.schedule.nil? ? st.transaction_at.to_date : st.schedule.to_s,
        from:     st.from.name,
        to:       st.to.name,
        category: st.category.name,
        type:     st.transaction_type,
        amount:   Mny.display_cents(st.amount),
        starting: st.transaction_at.to_date
      }
    end
  end

  def load_forecast
    opts = {}
    opts[:start_balance] = params[:start].to_i unless params[:start].blank?
    @days = opts[:days] = (params[:days] || 30).to_i
    @forecast = current_user.forecast opts
  end
end
