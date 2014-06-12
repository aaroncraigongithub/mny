class ScheduledTransactionsController < ApplicationController
  before_action :set_scheduled_transaction, only: [:show, :edit, :update, :destroy]

  # GET /scheduled_transactions
  def index
    @scheduled_transactions = ScheduledTransaction.all
  end

  # GET /scheduled_transactions/1
  def show
  end

  # GET /scheduled_transactions/new
  def new
    @scheduled_transaction = ScheduledTransaction.new
  end

  # GET /scheduled_transactions/1/edit
  def edit
  end

  # POST /scheduled_transactions
  def create
    @scheduled_transaction = ScheduledTransaction.new(scheduled_transaction_params)

    if @scheduled_transaction.save
      redirect_to @scheduled_transaction, notice: 'Scheduled transaction was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /scheduled_transactions/1
  def update
    if @scheduled_transaction.update(scheduled_transaction_params)
      redirect_to @scheduled_transaction, notice: 'Scheduled transaction was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /scheduled_transactions/1
  def destroy
    @scheduled_transaction.destroy
    redirect_to scheduled_transactions_url, notice: 'Scheduled transaction was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_scheduled_transaction
      @scheduled_transaction = ScheduledTransaction.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def scheduled_transaction_params
      params.require(:scheduled_transaction).permit(:user_id, :account_id, :transfer_to, :transaction_at, :repeats, :amount, :type)
    end
end
