#!/bin/bash -e

# Get Variables File
if [ -f ~/.config/hopper/vars ]; then
	source ~/.config/hopper/vars
fi

# ——————
# VAR FILE EDIT START
# ——————

# Default Editor
if [ -z "$editor" ] ; then
	editor="nano"
fi

# Shortcut to edit vars file
if  [[ $1 = "vars" ]]; then
	mkdir -p ~/.config/hopper
	$editor ~/.config/hopper/vars
	exit
fi

# ——————
# VAR FILE EDIT END
# ——————

# WP CLI Check
if ! [ -x "$(command -v wp)" ]; then
	echo -e '\033[91mError:\033[0m WP-CLI is not installed.' >&2
	exit 0
fi

# ——————
# VARIABLES START
# ——————

# Default Locale
if [ -z "$locale" ] ; then
	locale="en_US"
fi

# Style Variables
formatBreak="\033[90m―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――\033[0m"

# ——————
# VARIABLES END
# ——————

# ——————
# USER INPUT START
# ——————

# Welcome Text
echo ""
echo -e $formatBreak
echo "Hopper"
echo -e $formatBreak
echo ""
echo "Follow the instructions below to create a new WordPress site."
echo ""
echo "This setup does not create a vHost, but it will create a database"
echo "using the details in your .config/hopper/vars file, or set below."
echo ""
echo -e $formatBreak
echo ""

# WordPress User Inputs

echo -e $formatBreak
echo "1) WordPress User Details"
echo -e $formatBreak
echo ""

if [ -z "$wpuser" ] ; then
echo "WordPress Admin Username: "
read -e wpuser
echo ""
fi

if [ -z "$wpuser_email" ] ; then
echo "WordPress Admin Email: "
read -e wpuser_email
echo ""
fi

if [ -z "$wpuser_fname" ] ; then
echo "WordPress Admin First Name: "
read -e wpuser_fname
echo ""
fi

if [ -z "$wpuser_sname" ] ; then
echo "WordPress Admin Surname: "
read -e wpuser_sname
echo ""
fi

# Database Inputs

echo -e $formatBreak
echo "2) Database Details"
echo -e $formatBreak
echo ""

if [ -z "$db_user" ] ; then
echo "Datebase Username: "
read -e db_user
echo ""
fi

if [ -z "$db_pass" ] ; then
echo "Database Password: "
read -e db_pass
echo ""
fi

if [ -z "$dbname" ] ; then
echo "Database Name: "
read -e dbname
echo ""
fi

# Site Information Inputs

echo -e $formatBreak
echo "3) Site Details"
echo -e $formatBreak
echo ""

echo "Site Name: "
read -e sitename
echo ""

echo "Site URL (Include http://): "
read -e siteurl
echo ""

echo "Tagline: "
read -e tagline
echo ""

echo "Base Pages (Sererate page names with commas): "
read -e allpages
echo ""

# Plugin Option Inputs

echo -e $formatBreak
echo "4) Plugins"
echo -e $formatBreak
echo ""

echo "Install WooCommerce? (y/n)"
read -e woo
echo ""

echo "Install Redirection? (y/n)"
read -e redirection
echo ""

echo "Disable Blog? (y/n)"
read -e disableblog
echo ""

echo "Disable Comments? (y/n)"
read -e disablecomments
echo ""

echo "Disable Search? (y/n)"
read -e disablesearch

echo ""
echo -e $formatBreak
echo ""

# User confirmation
echo "Are you ready to proceed? (y/n)"
read -e run

# if the user didn't say no, then go ahead an install
if [ "$run" == n ] ; then
	echo ""
	echo -e $formatBreak
	echo ""
	echo "Aborted."
	echo ""
	exit 1
fi

echo ""
echo -e $formatBreak
echo ""
echo "Running install..."
echo ""

# ——————
# USER INPUT END
# ——————

# ——————
# BASE INSTALLATION START
# ——————

# WordPress Core download
wp core download --locale=$locale

# Wordpres Config creation with user details
wp core config --dbname=$dbname --dbuser=$db_user --dbpass=$db_pass

# Parse the current directory name
currentdirectory=${PWD##*/}

# Generate random 16 character password
password=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 16)

# Create database and install WordPress database structure
wp db create
wp core install --url="$siteurl" --title="$sitename" --admin_user="$wpuser" --admin_password="$password" --admin_email="$wpuser_email"
wp option update blogdescription "$tagline"

# Add a name to the admin user
wp user update $wpuser --first_name="$wpuser_fname" --last_name="$wpuser_sname" --display_name="$wpuser_fname $wpuser_sname"

# Discourage Search Engines
wp option update blog_public 0

# Remove the sample page and create a 'Home' page
wp post delete $(wp post list --post_type=page --posts_per_page=1 --post_status=publish --pagename="sample-page" --field=ID --format=ids)
wp post create --post_type=page --post_title=Home --post_status=publish --post_author=$(wp user get $wpuser --field=ID)

# Set the Front Page to our new 'Home' page
wp option update show_on_front 'page'
wp option update page_on_front $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename=home --field=ID --format=ids)

# Create pages from the comma seperated input
export IFS=","
for page in $allpages; do
	wp post create --post_type=page --post_status=publish --post_author=$(wp user get $wpuser --field=ID) --post_title="$(echo $page | sed -e 's/^ *//' -e 's/ *$//')"
done

# Flush URLs
wp rewrite structure '/%postname%/' --hard
wp rewrite flush --hard

# ——————
# BASE INSTALLATION END
# ——————

# ——————
# PLUGIN INSTALLATION START
# ——————

# Remove Default Plugins
wp plugin uninstall akismet hello

# WooCommerce Install Option
if [ "$woo" == y ] ; then
	active_plugins+=('woocommerce')
fi

# Redirection Install Option (Not activated on install)
if [ "$redirection" == y ] ; then
	plugins+=('redirection')
fi

# Disable Plugin Options
if [ "$disableblog" == y ] ; then
	active_plugins+=('disable-blog')
fi
if [ "$disablecomments" == y ] ; then
	active_plugins+=('disable-comments')
fi
if [ "$disablesearch" == y ] ; then
	active_plugins+=('disable-search')
fi

# Install plugins listed in var file and activate
wp plugin install ${active_plugins[*]} --activate

# Install plugins listed in var file
wp plugin install ${plugins[*]}

# ——————
# PLUGIN INSTALLATION END
# ——————

# ——————
# HOUSEKEEPING START
# ——————

# Create a new main menu
wp menu create "Main Navigation"

# Add pages to the main menu from the comma seperated input
export IFS=" "
for pageid in $(wp post list --order="ASC" --orderby="date" --post_type=page --post_status=publish --posts_per_page=-1 --field=ID --format=ids); do
	wp menu item add-post main-navigation $pageid
done

# Language Updates
wp core language update

# ——————
# HOUSEKEEPING END
# ——————

echo ""
echo -e $formatBreak
echo ""
echo "Installation complete! Here are the login details:"
echo ""
echo "Site URL: $siteurl"
echo ""
echo "Username: $wpuser"
echo "Password: $password"
echo ""
echo -e $formatBreak
