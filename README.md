# mny


A rails app for managing your money

Loosely based on [KMyMoney](http://kmymoney2.sourceforge.net/), `mny` attempts to allow anyone to set up a server based personal money tracking software.

This is still under heavy development, and not yet complete.  Once a first version is ready, this file will contain better documentation.

## Setting up

Clone the repo and adjust your server settings to make it available on your domain.  There are no special configuration caveats -- it's a straightforward Rails app.

### Database

For security, `database.yml` is kept out of the repository, so you'll need to create your own.

## Usage

Until a web based front end is done, there is a fairly feature complete rake task suite that allows you to add and edit transactions, set up scheduled payments and forecast balances.  Parameters are passed through ENV variables, prefixed with MNY_.
