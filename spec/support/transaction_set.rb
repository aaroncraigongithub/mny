shared_examples "a filtered transaction set" do |factory, filters, params|

  let(:user)            { create(factory) }
  let(:transaction_set) {
    filters[:account] = user.account(:default) if filters[:account].blank?
    filters[:account] = user.accounts.last if filters[:account] == :other
    filters[:category] = user.categories.first.name unless filters[:category].blank?

    user.transaction_set(filters)
  }

  before(:each) do
    sign_in user

    params[:account] = user.accounts.last.name unless params[:account].blank?
    params[:category] = user.categories.first.name unless params[:category].blank?
    get :index, filters: params
  end

  it "assigns transaction_set" do
    subject{ assigns(:transaction_set) }
  end

  it "assigns transaction_set with a Mny::TransactionSet" do
    expect(assigns(:transaction_set)).to be_a_kind_of(Mny::TransactionSet)
  end

  it "has the expected count" do
    expect(assigns(:transaction_set).count).to eq transaction_set.count
  end

end
