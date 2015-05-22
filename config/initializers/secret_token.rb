# This file was generated by 'rake generate_secret_token', and should
# not be made visible to public.

# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.


BuckyBox::Application.config.secret_token = if Rails.env.development? || Rails.env.test?
  "c3df8f74b5d59798bb4f5b1b63021d38c09dfaa7af81650d4b744121c1dc2de3753a275f1979976365c5ecfe1b1fa4077abae03a68ef1a4b16bd765927e76c9a"
else
  ENV.fetch("SECRET_TOKEN")
end