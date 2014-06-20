class ForecastController < ApplicationController

  def index
    @days       = (params[:days] || 30).to_i
    @forecast   = current_user.forecast @days
    @scheduled  = current_user.scheduled_transactions.collect {|st|
      {
        instance: st,
        account:  st.account.name,
        date:     st.schedule.nil? ? st.transaction_at.to_date : st.schedule.to_s,
        from:     st.from.name,
        to:       st.to.name,
        category: st.category.name,
        type:     st.transaction_type,
        amount:   Mny.display_cents(st.amount),
        starting: st.transaction_at.to_date
      }
    }
  end

end
