# Hopper

A tool to quickly spin up a new WordPress site in minutes.

## Usage

Navigate to the directory where the new WordPress site will be installed and run the `hopper` command.

Answer the questions when prompted, at the end of the installation you'll be provided with the username and password to login.

## Installation
To install Hopper, ensure that your system meets the following requirements:

* WP-CLI

To install Hopper on your system, download or clone this repo, navigate to it in your terminal and run the following commands:

~~~~
chmod +x hopper.sh
sudo cp ./hopper.sh /usr/local/bin/hopper
~~~~

## Variables

If you regularly setup WordPress sites and use the same plugins on each one, or if you share the database credentials across projects in your dev environment, the variables file will come in handy.

The Variables file lives in `~/.config/hopper/vars`.

It can easily be created by running the command `hopper vars`. This command can also be ran to quickly edit the file. You can specify your preferred editor in the vars file too. 

Here's and example of this file:

~~~~
# Locale
locale='en_GB'

# Editor
editor='code'

# Admin User Details
wpuser='admin'
wpuser_email=''
wpuser_fname=''
wpuser_sname=''

# Database Details
db_user=''
db_pass=''

# Plugins (Activated on install)
active_plugins=(
	"akismet"
	"advanced-custom-fields"
)

# Plugins
plugins=(
	"wordpress-seo"
	"hello"
)
~~~~