class AccountsController < ApplicationController
  before_action :set_account, only: [:show, :edit, :update, :destroy]

  # GET /accounts
  def index
    @accounts = current_user.accounts
    @account_summary = @accounts.collect{ |account| {account: account.name, balance: Mny.display_cents(account.balance)} }
  end

  # GET /accounts/1
  def show
  end

  # GET /accounts/new
  def new
    @account = Account.new
  end

  # GET /accounts/1/edit
  def edit
  end

  # POST /accounts
  def create
    @account = current_user.accounts.create(account_params)

    if @account.save
      redirect_to accounts_url, notice: 'Success!'
    else
      render :new
    end
  end

  # PATCH/PUT /accounts/1
  def update
    if @account.update(account_params)
      redirect_to accounts_url, notice: 'Updated!'
    else
      render :edit
    end
  end

  # DELETE /accounts/1
  def destroy
    @account.destroy
    redirect_to accounts_url, notice: 'Deleted!'
  end

  private

    def set_account
      @account = Account.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:user_id, :name)
    end
end
