require 'rails_helper'

describe ForecastController, type: :controller do

  let(:headless) { Headless.new }

  before(:each) do
    auth_user :user_with_a_balance

    headless.start
  end

  after(:all) do
    headless.destroy
  end

  let(:browser) { Watir::Browser.new }

  context 'GET /forecast' do
    let(:path) { '/forecast' }
    let(:days) { rand(45..60).to_s }

    before(:each) do
      browser.goto path
    end

    it 'sends the days field' do
      browser.text_field(name: 'days').set days
      browser.button(type: 'submit').click
    end
  end
end
