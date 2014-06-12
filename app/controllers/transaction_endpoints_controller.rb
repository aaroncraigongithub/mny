class TransactionEndpointsController < ApplicationController
  before_action :set_transaction_endpoint, only: [:show, :edit, :update, :destroy]

  # GET /transaction_endpoints
  def index
    @transaction_endpoints = TransactionEndpoint.all
  end

  # GET /transaction_endpoints/1
  def show
  end

  # GET /transaction_endpoints/new
  def new
    @transaction_endpoint = TransactionEndpoint.new
  end

  # GET /transaction_endpoints/1/edit
  def edit
  end

  # POST /transaction_endpoints
  def create
    @transaction_endpoint = TransactionEndpoint.new(transaction_endpoint_params)

    if @transaction_endpoint.save
      redirect_to @transaction_endpoint, notice: 'Transaction endpoint was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /transaction_endpoints/1
  def update
    if @transaction_endpoint.update(transaction_endpoint_params)
      redirect_to @transaction_endpoint, notice: 'Transaction endpoint was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /transaction_endpoints/1
  def destroy
    @transaction_endpoint.destroy
    redirect_to transaction_endpoints_url, notice: 'Transaction endpoint was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction_endpoint
      @transaction_endpoint = TransactionEndpoint.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def transaction_endpoint_params
      params.require(:transaction_endpoint).permit(:user_id, :label)
    end
end
