class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [:show, :edit, :update, :destroy]
  before_action :set_filters, only: [:index]
  before_action :filter_transactions, only: [:index]

  # GET /transactions
  def index
  end

  # GET /transactions/1
  def show
  end

  # GET /transactions/new
  def new
    @transaction = Transaction.new
  end

  # GET /transactions/1/edit
  def edit
  end

  # POST /transactions
  def create
    @transaction = Transaction.new(transaction_params)

    if @transaction.save
      redirect_to @transaction, notice: 'Transaction was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /transactions/1
  def update
    if @transaction.update(transaction_params)
      redirect_to @transaction, notice: 'Transaction was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /transactions/1
  def destroy
    @transaction.destroy
    redirect_to transactions_url, notice: 'Transaction was successfully destroyed.'
  end

  private
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end

    def set_filters
      @filters = params[:filters] || {}
    end

    def filter_transactions
      filters = {}

      after_date = @filters[:after].blank? ? Time.now.getutc - 30.days : Date.parse(@filters[:after]).to_time

      filters[:transacted_after]    = after_date
      filters[:transacted_before]   = Date.parse(@filters[:before]).to_time unless @filters[:before].blank?
      filters[:account]             = current_user.account(@filters[:account] || :default)
      filters[:transaction_type]    = @filters[:type].to_sym unless @filters[:type].blank?

      @transaction_set = current_user.transaction_set(filters)
    end

    # Only allow a trusted parameter "white list" through.
    def transaction_params
      params.require(:transaction).permit(:user_id, :account_id, :transaction_endpoint_id, :transfer_to, :category_id, :type, :amount, :transaction_at, :status)
    end
end
