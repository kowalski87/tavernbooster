class OrdersController < ApplicationController
  # GET /orders
  # GET /orders.json
  def index
    @orders = Order.all
    @total = @orders.inject(0) do |acc, ord|
      acc += ord.total_price
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @orders }
    end
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
    @order = Order.find(params[:id])
    @courses = @order.course_orders.inject([]) do |acc, co|
      course = Course.find(co.course_id)
      acc << {name: course.name, number_required: co.number_required, 
        number_cooked: co.number_cooked, price: course.price, subtotal: course.price * co.number_required}
    end
    
    @total_price = @order.course_orders.inject(0) do |acc, co|
      course = Course.find(co.course_id)
      acc += course.price * co.number_required
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @order }
    end
  end

  # GET /orders/new
  # GET /orders/new.json
  def new
    @order = Order.new
    @course_types = CourseType.all
	  @courses = @order.formatted_courses
    @allowed_tables = Table.find_all_by_user_id(current_user.id)
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @order }
    end
  end

  # GET /orders/1/edit
  def edit
    @order = Order.find(params[:id])
    @courses = @order.formatted_courses
    @course_types = CourseType.all
    @allowed_tables = Table.find_all_by_user_id(current_user.id)
  end

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(params[:order])
    @order.user_id = current_user.id
    ordered = params[:courses].select {|k,v| v != "0"}     
    respond_to do |format|
      if @order.save
        ordered.each do |course_id, number_required|
          CourseOrder.create(:course_id => course_id.to_i, :order_id => @order.id, :number_required => number_required)
        end
        format.html { redirect_to @order, notice: 'Order was successfully created.' }
        format.json { render json: @order, status: :created, location: @order }
      else
        format.html { render action: "new" }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /orders/1
  # PUT /orders/1.json
  def update
    @order = Order.find(params[:id])

    respond_to do |format|
      if @order.update_attributes(params[:order])
        format.html { redirect_to @order, notice: 'Order was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order = Order.find(params[:id])
    @order.destroy

    respond_to do |format|
      format.html { redirect_to orders_url }
      format.json { head :ok }
    end
  end
  
  def cook
    course_id = params[:course_id]
    order_id = params[:order_id]
    course_order = CourseOrder.find_by_course_id_and_order_id(course_id,order_id)
    new_val = course_order.number_cooked + 1
    sql = "UPDATE 'course_orders' SET 'number_cooked' = #{new_val} WHERE 'course_orders'.'course_id' = 
      #{course_id} AND 'course_orders'.'order_id' = #{order_id}"
    ActiveRecord::Base.connection.execute(sql)
    course_order = CourseOrder.find_by_course_id_and_order_id(course_id,order_id)
    number_needed = course_order.number_needed
    number_cooked = course_order.number_cooked
    
    respond_to do |format|
      format.json { render json: {number_cooked: number_cooked, number_needed: number_needed} }
    end
  end
end
