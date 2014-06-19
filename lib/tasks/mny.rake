# # Rake tasks for Mny
#
# The rake tasks herein may be used as a cli alternative to the (yet to be built) web interface for Mny, or as a test console.

namespace :mny do

  namespace :users do

    desc "Create a user account"
    task :new => :environment do
      email = ENV['MNY_EMAIL']
      complain("You must supply MNY_EMAIL") and exit if email.blank?

      User.create! email: email, password: SecureRandom.hex(10)
    end

  end

  namespace :accounts do

    desc "Create an account"
    task :new => :environment do
      with_env do |user, params|
        name = params[:account] || "Account #{ user.accounts.count + 1}"
        user.accounts.create! name: name, is_default: trueish(params[:default])
      end
    end

    desc "List a user's accounts"
    task :list => :environment do
      with_env do |user, params|

        accounts = []
        user.accounts.each do |account|
          name = account.name
          name<< ' *' if account.is_default

          accounts<< {
            name:     name,
            balance:  display_cents(account.balance)
          }
        end

        accounts<< {name: "Net worth", balance: display_cents(user.net_worth)}
        Formatador.display_table(colorize_data(accounts), [:name, :balance])
      end
    end
  end

  namespace :transactions do

    desc "List transactions"
    task :list => :environment do
      with_env do |user, params|
        filters = {}
        [:transacted_before, :transacted_after, :from, :to, :transfer_to, :transfer_from, :account, :category, :status, :amount, :type].each do |k|
          next if params[k].nil?

          if [:transacted_before, :transacted_after].include?(k)
            filters[k] = safe_date(params[k])
          elsif [:transfer_from, :transfer_to, :account].include?(k)
            filters[k] = user.account(params[k])
            complain("Can't find an account named #{ params[k] }") and exit if filters[k].nil?
          elsif [:from, :to].include?(k)
            endpoint = TransactionEndpoint.find_by_name(params[k])
            complain("Can't find an endpoint #{ params[k] }") and exit if endpoint.nil?
            filters[:transaction_endpoint] = [] if filters[:transaction_endpoint].nil?
            filters[:transaction_endpoint]<< endpoint
          elsif k == :category
            filters[k] = user.categories.find_by_name(params[k])
            complain("Can't find a category named #{ params[k] }") and exit if filters[k].nil?
          elsif k == :type
            filters[:transaction_type] = params[k]
          else
            filters[k] = params[k]
          end
        end

        filters[:transaction_type] = [:deposit, :withdrawal] if trueish(params[:no_transfers])

        data = user.transaction_set(filters).report
        Formatador.display_table(colorize_data(data), [:id, :account, :date, :from, :to, :category, :status, :type, :amount, :balance])
      end
    end

    desc "List scheduled transactions"
    task :scheduled => :environment do
      with_env do |user, params|
        data = []
        user.scheduled_transactions.each do |st|
          data<< {
            id: st.id,
            account:  st.account.name,
            date:     st.schedule.nil? ? st.transaction_at.to_date : st.schedule.to_s,
            from:     st.from.name,
            to:       st.to.name,
            category: st.category.name,
            type:     st.transaction_type,
            amount:   display_cents(st.amount)
          }
        end

        Formatador.display_table(colorize_data(data), [:id, :account, :date, :from, :to, :category, :type, :amount])
      end
    end

    desc "Edit a transaction"
    task :edit => :environment do
      with_env do |user, params|
        transaction                 = Transaction.find(params[:tid])
        transaction.amount          = params[:amount] unless params[:amount] == 0
        transaction.category        = Category.find_or_create_by(user_id: user.id, name: params[:category]) unless params[:category].blank?
        transaction.transaction_at  = safe_date(params[:date]) unless params[:date].blank?
        transaction.status          = params[:status] unless params[:status].blank?
        transaction.to              = params[:to] unless params[:to].blank?
        transaction.from            = params[:from] unless params[:from].blank?
        transaction.save!
      end
    end

    desc "Delete a transaction"
    task :delete => :environment do
      with_env do |user, params|
        Transaction.destroy(params[:tid])
      end
    end

    desc "Edit a scheduled transaction"
    task :edit_scheduled => :environment do
      with_env do |user, params|
        transaction                 = ScheduledTransaction.find(params[:tid])
        transaction.amount          = params[:amount] unless params[:amount] == 0
        transaction.category        = Category.find_or_create_by(user_id: user.id, name: params[:category]) unless params[:category].blank?
        transaction.transaction_at  = safe_date(params[:date]) unless params[:date].blank?
        transaction.schedule        = params[:schedule] unless params[:schedule].blank?
        transaction.to              = params[:to] unless params[:to].blank?
        transaction.from            = params[:from] unless params[:from].blank?
        transaction.save!
      end
    end

    desc "Delete a scheduled transaction"
    task :delete_scheduled => :environment do
      with_env do |user, params|
        ScheduledTransaction.destroy(params[:tid])
      end
    end
  end

  desc "Make a deposit"
  task :deposit => :environment do
    with_env(:amount) do |user, params|
      user.deposit(params[:amount], to: params[:to], from: params[:from] || generice_source(user), category: params[:category], transaction_at: safe_date(params[:date]), status: params[:status])
    end
  end

  desc "Make a withdrawal"
  task :withdraw => :environment do
    with_env(:amount) do |user, params|
      user.withdraw(params[:amount], from: params[:from], to: params[:to] || generic_recipient(user), category: params[:category], transaction_at: safe_date(params[:date]), status: params[:status])
    end
  end

  desc "Transfer between accounts"
  task :transfer => :environment do
    with_env(:amount) do |user, params|
      user.transfer(params[:amount], from: params[:from], to: params[:to], transaction_at: safe_date(params[:date]), status: params[:status])
    end
  end

  desc "Schedule a deposit"
  task :will_deposit => :environment do
    with_env(:amount) do |user, params|
      t_params = { to: params[:to], from: params[:from] || generice_source(user), category: params[:category], transaction_at: safe_date(params[:date]), status: params[:status] }
      t_params[:on] = params[:on] unless params[:on].nil?
      t_params[:schedule] = params[:schedule] unless params[:schedule].nil?

      user.will_deposit(params[:amount], t_params)
    end
  end

  desc "Schedule a withdrawal"
  task :will_withdraw => :environment do
    with_env(:amount) do |user, params|
      t_params = { from: params[:from], to: params[:to] || generic_recipient(user), category: params[:category], transaction_at: safe_date(params[:date]), status: params[:status] }
      t_params[:on] = params[:on] unless params[:on].nil?
      t_params[:schedule] = params[:schedule] unless params[:schedule].nil?

      user.will_withdraw(params[:amount], t_params)
    end
  end

  desc "Schedule a transfer between accounts"
  task :will_transfer => :environment do
    with_env(:amount) do |user, params|
      t_params = { from: params[:from], to: params[:to], transaction_at: safe_date(params[:date]), status: params[:status] }
      t_params[:on] = params[:on] unless params[:on].nil?
      t_params[:schedule] = params[:schedule] unless params[:schedule].nil?

      user.will_transfer(params[:amount], t_params)
    end
  end

  desc "Forecast for a given number of days"
  task :forecast => :environment do
    with_env do |user, params|
      forecast = user.forecast(params[:days])
      Formatador.display_table(colorize_data(forecast.report), [:id, :account, :date, :from, :to, :category, :type, :amount, :balance])

      Formatador.display_line("[magenta]Forecast to #{ forecast.end_date.to_date }[/]")
      summary_table = [
        {snapshot: "Highest balance", balance: display_cents(forecast.high)},
        {snapshot: "Lowest balance", balance: display_cents(forecast.low)},
      ]
      Formatador.display_table(colorize_data(summary_table), [:snapshot, :balance])

      negatives = forecast.negative_balances
      if negatives.count > 0
        Formatador.display_line("[red]Negative balance detected![/]")

        n_data = negatives.sort.map { |date, balance| { date: date, balance: display_cents(balance) } }
        Formatador.display_table(colorize_data(n_data), [:date, :balance])
      end
    end
  end
end

def with_env(*args)
  required = args.count > 0 ? (args[0].is_a?(Array) ? args[0] : [args[0]]) : []

  user = user_from_env
  raise "Cannot find a user with '#{ ENV['MNY_USER'] }'" if user.nil?

  params = transaction_from_env

  required.each do |key|
    raise "Missing #{ key }" if params[key].nil?
  end

  yield user, params
end

def transaction_from_env
  env = {}
  ENV.each do |k, v|
    if k =~ /^MNY/
      our_key = k.downcase.sub('mny_', '').to_sym
      env[our_key] = v
    end
  end

  unless env[:schedule].nil?
    rrule = Hash[env[:schedule].split(';').map {|v| v.split('=') }]
    env[:schedule] = IceCube::Schedule.new do |s|
      interval = (rrule['INT'] || 1).to_i

      # For now, limited ICAL support

      # Daily allows for INT
      # ie: FREQ=D;INT=4 - every four days
      if rrule['FREQ'] == 'D'
        s.add_recurrence_rule IceCube::Rule.daily(interval)
      end

      # Weekly allows for BYDAY and INT
      # ie: FREQ=W;BYDAY=MO,TU - every Monday and Tuesday
      # ie: FREQ=W;BYDAY=FR;INT=2 - every other Friday
      if rrule['FREQ'] == 'W'
        days = []
        unless rrule['BYDAY'].nil?
          day_map = {'MO' => :monday, 'TU' => :tuesday, 'WE' => :wednesday, 'TH' => :thursday, 'FR' => :friday, 'SA' => :saturday, 'SU' => :sunday}
          rrule['BYDAY'].split(',').each do |d|
            days<< day_map[d]
          end

          s.add_recurrence_rule IceCube::Rule.weekly(interval).day(days)
        end
      end

      # Monthly allows for BYDAY (an int indicating date in this case)
      # ie: FREQ=M;BYDAY=15 - every 15th of the month
      # ie: FREQ=M;BYDAY=15;INT=2 - the 15th every other month
      if rrule['FREQ'] == 'M'
        rule = IceCube::Rule.monthly(interval)
        rule.day_of_month(rrule['BYDAY'].to_i) unless rrule['BYDAY'].nil?

        s.add_recurrence_rule rule
      end
    end
  end

  env
end

def generic_source(user)
  "Income source #{ user.transaction_endpoints.count }"
end

def generic_recipient(user)
  "Payment recipient #{ user.transaction_endpoints.count }"
end

def safe_date(val)
  val.nil? ? Time.now : Time.parse(val)
end

def user_from_env
  user_id = ENV['MNY_USER']
  user_id.blank? ? User.first : User.find(user_id)
end

def colorize_data(data)
  colors = {
    from:     'yellow',
    to:       'blue',
    category: 'light_black',
    status: Proc.new { |v, row|
      {
        c:   'light_black',
        r:   'white',
        u:   'yellow',
      }[v[0].to_sym]
    },
    type: Proc.new { |v, row|
      {
        deposit:      'cyan',
        withdrawal:   'magenta',
        transfer_in:  'light_black',
        transfer_out: 'light_black'
      }[row[:type].to_sym]
    },
    amount: Proc.new { |v, row|
      clean = row[:type].gsub(/\[.+?\]/, '')
      clean == '-' ? 'magenta' : (['t+', 't-'].include?(clean) ? 'light_black' : 'cyan')
    },
    balance: Proc.new { |v, row|
      row[:balance].sub(/[^\d]/, '').to_i < 0 ? 'red' : 'green'
    }
  }

  value_map = {
    type: Proc.new { |v, row|
      {
        deposit:      '+',
        withdrawal:   '-',
        transfer_in:  't+',
        transfer_out: 't-'
      }[v.to_sym]
    },
    status: Proc.new { |v, row|
      v[0]
    }
  }

  data.each do |row|
    row.each do |k, v|
      m = value_map[k] || v
      m = m.call(v, row) if m.is_a?(Proc)

      c = colors[k] || 'light_black'
      c = c.call(m, row) if c.is_a? Proc

      row[k] = "[#{ c }]#{ m }[/]"
    end
  end
end

def trueish(val)
  val ||= 'false'
  !(/^(true|yes|t|y|1)/.match(val.downcase).nil?)
end

# Display the given integer as a currency amount (@TODO use the currency of the transaction)
def display_cents(cents)
  sprintf("$ %5.02f", cents.to_f / 100)
end

def complain(message)
  Formatador.display_line("[red]#{ message }[/]")
  true
end
