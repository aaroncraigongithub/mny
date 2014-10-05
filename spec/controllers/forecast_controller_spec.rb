require 'rails_helper'

describe ForecastController do

  before(:each) do
    auth_user(:user_with_a_balance)
  end

  context 'GET /forecast' do

    before(:each) do
      get :index
    end

    it "renders the index template" do
      puts response.body
      # expect(response).to be_successful
      expect(response).to render_template('index')
    end
  end

  context 'POST /forecast' do
    let(:start)     { rand(1000..1500) }
    let(:days)      { rand(30..45) }
    let(:forecast)  { assigns(:forecast) }

    before(:each) do
      post :forecast, {start: start, days: days}
    end

    it "renders the index template" do
      expect(response).to be_successful
      expect(response).to render_template('forecast')
    end

    it "assigns @days" do
      expect(assigns(:days)).to eq(days)
    end

    it "assigns @forecast" do
      expect(forecast).to be_a_kind_of(Mny::Forecast)
    end

    it "sets the start balance" do
      expect(forecast.instance_variable_get('@balance')).to eq(start)
    end

    it "sets the forecast days" do
      expect(forecast.instance_variable_get('@end_date').to_date).to \
        eq((Time.now + days.days).to_date)
    end
  end
end
