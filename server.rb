require 'stripe'
require 'sinatra'
require 'dotenv/load'

# This is your test secret API key.
Stripe.api_key = ENV['STRIPE_API_KEY']

set :static, true
set :port, 4242

YOUR_DOMAIN = ENV['APP_DOMAIN']

post '/create-checkout-session' do
  content_type 'application/json'

  session = Stripe::Checkout::Session.create({
    line_items: [{
      # Provide the exact Price ID (e.g. pr_1234) of the product you want to sell
      price: ENV['STRIPE_PRICE_ID'],
      quantity: 1,
    }],
    mode: 'payment',
    # https://docs.stripe.com/payments/checkout/custom-success-page?payment-ui=stripe-hosted#modify-the-success-url
    success_url: YOUR_DOMAIN + '/success?session_id={CHECKOUT_SESSION_ID}',
    cancel_url: YOUR_DOMAIN + '/cancel',
    automatic_tax: {enabled: true},
    metadata: {one: 1, two: "duo"},
  })
  redirect session.url, 303
end

get '/success' do
  puts "=== Success Request ==="
  puts "Headers:"
  request.env.select { |k,v| k.start_with? 'HTTP_' }.each do |k,v|
    puts "  #{k}: #{v}"
  end
  puts "Params:"
  puts request.params.inspect

  session = Stripe::Checkout::Session.retrieve(
    {
      id: params[:session_id],
      expand: ['line_items']
    }
  )
  puts "Session:"
  puts session.inspect

  puts "Line Items:"
  puts session.line_items.data.inspect

  if session.customer then
    customer = Stripe::Customer.retrieve(session.customer)
    puts "Customer:"
    puts customer.inspect
  end

  content_type 'text/html'
  <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Thanks for your order!</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <section>
    <p>
      We appreciate your business! If you have any questions, please email
      <a href="mailto:orders@example.com">orders@example.com</a>.
    </p>
  </section>
</body>
</html>
  HTML
end

get '/cancel' do
  puts "=== Cancel Request ==="
  puts "Headers:"
  request.env.select { |k,v| k.start_with? 'HTTP_' }.each do |k,v|
    puts "  #{k}: #{v}"
  end
  puts "Params:"
  puts request.params.inspect

  content_type 'text/html'
  <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Checkout canceled</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <section>
    <p>Forgot to add something to your cart? Shop around then come back to pay!</p>
  </section>
</body>
</html>
  HTML
end
