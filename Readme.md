
# Sample Intercom Oauth App

- This is a sample app Oauth app that can be deployed to Heroku 
- Code mostly from https://developers.intercom.io/docs/setting-up-oauth 

## Setup
- Get dependencies: `bundle install` (Requires http://bundler.io/)
- Create configuration: Make a `.env` file and populate configurations
- Run: `ruby app.rb`

## Environment Variables
### Required
https://app.intercom.io/a/apps/_/settings/oauth

- `client_id`
- `client_secret`

### Optional 

- `self_ssl`: set to `1` only if you have certificate files
   - Uses `pkey.pem` and `cert.cert` in the same directory (see details in the app.rb source)
   - Generate files via `openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout pkey.pem -out cert.crt`
- `redirect_url`: set if you want to manually specify your callback e.g. for dev environment
- `PORT`: port to attach to
