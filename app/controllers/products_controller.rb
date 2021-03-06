class ProductsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :purchase, :pay, :done]
  before_action :set_product, only:[:show, :edit, :update, :destroy, :purchase, :pay]
  before_action :edit_validate, only: [:edit, :update, :destroy]
  before_action :pay_validate, only: [:purchase]
  before_action :set_api_key, only:[:purchase, :pay]
  before_action :set_parents, only: [:new, :create]

  def index
    @products = @search.result.where.not(sold_out_flg: 2).page(params[:page]).per(100)
  end

  def new
    @product = Product.new
    @product.images.build
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to product_path(@product.id)
    else
      render new_product_path
    end
  end

  def show
    @products_kind = Product.where(kind_id: @product.kind_id).limit(3)
    @comment = Comment.new
    @comments = @product.comments.includes(:user)
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to product_path(@product.id)
    else
      render :edit
    end
  end

  def destroy
    if @product.destroy
      redirect_to mypage_listings_path
    else
      render :show
    end
  end

  def set_parents
    @parents = Kind.where(ancestry: nil)
  end

  def search
    respond_to do |format|
      format.html
      format.json do
        if params[:parent_id]
          @childrens = Kind.find(params[:parent_id]).children
        elsif params[:children_id]
          @grandChilds = Kind.find(params[:children_id]).children
        end
      end
    end
  end

  def purchase
    if !@card.blank?
      customer = Payjp::Customer.retrieve(@card.customer_id)
      @customer_card = customer.cards.retrieve(@card.card_id)
      @card_brand = @customer_card.brand
      case @card_brand
      when "Visa"
        @card_src = "cards/visa.svg"
      when "JCB"
        @card_src = "cards/jcb.svg"
      when "MasterCard"
        @card_src = "cards/master-card.svg"
      when "American Express"
        @card_src = "cards/american_express.svg"
      when "Diners Club"
        @card_src = "cards/dinersclub.svg"
      when "Discover"
        @card_src = "cards/discover.svg"
      end
    end
  end
  
  def pay
    if charge = Payjp::Charge.create(
      amount: @product.price,
      customer: @card.customer_id,
      currency: 'jpy',
      )
      current_user.buyer_users.create(product_id: @product.id)
      @product.sold_out_flg = 1
      @product.save

      redirect_to done_products_path
    else
      render :purchase
    end
  end

  def done

  end

  private
  def product_params
    params.require(:product).permit(:name,
                                    :introduce,
                                    :price,
                                    :kind_id,
                                    :brand_id,
                                    :condition_id,
                                    :postage_id,
                                    :shipment_id,
                                    :prefecture_id,
                                    images_attributes: [
                                      :id,
                                      :image,
                                      :_destroy
                                    ]).merge(user_id: current_user.id)
  end

  def set_product
    @product = Product.find(params[:id])
  end

  def set_api_key
    Payjp.api_key = Rails.application.credentials[:payjp][:ACCESS_KEY]
    @card = current_user.cards.find_by(default_flg: 1)
  end

  def edit_validate
    if @product.user_id != current_user.id
      redirect_to root_path
    end
  end

  def pay_validate
    if @product.user_id == current_user.id || @product.sold_out_flg != 0
      redirect_to root_path
    end
  end
end
