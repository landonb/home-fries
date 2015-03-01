# File: vendor_mediawiki.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2015.03.01
# Project Page: https://github.com/landonb/home_fries
# Summary: MediaWiki (and PHP, etc.) setup script.
# License: GPLv3

# Configuration
# -------------

# Set to true if you want to install Mediawiki.
# 2015.01.25: MW is great as a web application, but for developer
# notes, using simple reST documents is a lot easier, so installing
# MediaWiki is disabled by default.
DO_INSTALL_MEDIAWIKI=false

# Custom MediaWiki database -- If you a Wiki, specify it here.
USE_WIKIDB_DUMP=""

# Remote resources. Maybe.
# ------------------------

# If the Wiki db is not already local, specify the HTTP address
# and username and password to get it.
REMOTE_RESOURCES_URI=""
REMOTE_RESOURCES_USER=""
REMOTE_RESOURCES_PASS=""

  # If installing mediawiki, configure these options.
  # The passwords are optional and will be auto-generated if not supplied.
  USE_WIKINAME="My Wiki Site Name"
  # USE_PSQLWIKIPWD="" # Auto-generated if not set here.
  USE_WIKIUSERNAME="Your Name"
  # USE_WIKIUSERPASS="" # Auto-generated if not set here.
  USE_WIKISITELOGO="${script_absbase}/assets/mediawiki_custom_crushinator.png"
  USE_WIKIDB_DUMP="path/to/mediawiki.dump.xml.gz"


# PHP Options
# -----------

#PHP_5X=5.4.24
#PHP_5X=5.5.10
#   2014.05.14: I [lb] $(sudo apt-get upgrade)ed and PHP got
#               whacked, so I'm re-installing it. (Something
#               reverted to using the PHP from the package
#               repository and the one installed herein.)
#PHP_5X=5.5.12
# 2014.11.07: And again PHP got whacked, so reinstalling.
PHP_5X=5.6.2

# Set the timezone on the Wiki installation.
# [lb] apologizes if you're not here, but we're nearby, in the same zone.
# If you're not here, change it, or leave it blank.
USE_TIMEZONE="America\/Menominee"
# USE_TIMEZONE=""
# PRIORITY_5: Use a Geo IP locator and deduce the timezone, e.g., all of:
#  wget http://freegeoip.net/csv/
#  wget http://freegeoip.net/xml/
#  wget http://freegeoip.net/json/
# return the location for the requesting IP address (you can also send any IP).
# This feature is similar to the Ubuntu and Mint installers which guess your
# timezone based on your IP addy.

# APC User Cache installation options
# -----------------------------------

#APCU_V4=apcu-4.0.2
#APCU_V4=4.0.4
#APCU_TGZ="v${APCU_V4}.tar.gz"
APCU_V4=4.0.7
APCU_TGZ="apcu-${APCU_V4}.tgz"

# MediaWiki installation options
# ------------------------------

#mwiki_basename="mediawiki-1.22.0"
#mwiki_basename="mediawiki-1.22.5"
mwiki_basename="mediawiki-1.23.6"
#mwiki_wgetpath="http://download.wikimedia.org/mediawiki/1.22/${mwiki_basename}.tar.gz"
mwiki_wgetpath="http://download.wikimedia.org/mediawiki/1.23/${mwiki_basename}.tar.gz"
mwiki_basepath=/ccp/var/cms/${mwiki_basename}

# Name the Wiki. This is just cosmetic. By default, for no reason, we'll use
# the i18n'ion of the username, e.g., for excensus, [e6s], but name it what
# you will.
#  Note the space after the colon and before the -1; otherwise,
#  "defaults to full string, as in ${parameter:-default}."
#   http://tldp.org/LDP/abs/html/string-manipulation.html
USE_WIKINAME="[${LOGNAME:0:1}$((${#LOGNAME}-2))${LOGNAME: -1}]"
# Or name the Wiki whatever you like:
#  USE_WIKINAME="Triki"

# Set the Postgres user's MediaWiki password, it you want. By default,
# we generate a random password, since it's stored in LocalSettings.php
# and you won't normally need to use it.
if [[ ! -e ${script_absbase}/setup-exc-mwiki_pwd ]]; then
  USE_PSQLWIKIPWD=$(pwgen -n 16 -s -N 1 -y)
  echo "${USE_PSQLWIKIPWD}" > ${script_absbase}/setup-exc-mwiki_pwd
else
  USE_PSQLWIKIPWD=`cat ${script_absbase}/setup-exc-mwiki_pwd`
fi

# Set the Postgres username and password. This is what's specified in
# LocalSettings.php.
USE_WIKIUSERNAME="mediawiki_psql_user"
# Also set the Postgres user's password. On a development machine, we use
# Postgres' pg_ident.conf to control which Linux user maps to which Postgres
# user, so the Wiki user's password doesn't really matter.
# If you want more security, set a random, strong password:
#  USE_WIKIUSERPASS=$(pwgen -n 16 -s -N 1 -y)
# But usually this is just fine:
USE_WIKIUSERPASS='mediawiki_psql_pass'

# Set a custom Wiki logo if you will, otherwise behold the crushinator.
USE_WIKISITELOGO="${script_absbase}/assets/mediawiki_custom_crushinator.png"
#USE_WIKISITELOGO="${script_absbase}/assets/mediawiki_custom_cyclopath.png"
#USE_WIKISITELOGO="${script_absbase}/assets/mediawiki_custom_retros.png"

# PHP5 Timezone option
# --------------------

# HARDCODE: freegeoip.net isn't the only tz service, but it works,
# and the timezone is only used for PHP install, which you probably
# won't be installing if you're all HTML5 and whatnot.
TIMEZONE_RESOLVE_SERVICE="http://freegeoip.net/csv/"
if [[ -z $USE_TIMEZONE ]]; then
  cd /tmp
  wget -O machine.timezone.csv ${TIMEZONE_RESOLVE_SERVICE}
  if [[ $? -eq 0 ]]; then
    # The timezone is in the 8th posit, e.g.,
    # 1.2.3.4,US,United States,MN,Minnesota,Minneapolis,55401,America/Chicago,45.00,-93.25,613
    USE_TIMEZONE=$(cat machine.timezone.csv | awk -F ',' '{print $8}')
  else
    echo "WARNING: Could not determine friendly timezone name."
    USE_TIMEZONE=""
  fi
  /bin/rm machine.timezone.csv
fi

# ======================================================
# Very Dated/Very Unused: PHP/APC/Intl/MediaWiki Install

stage_4_intl_install () {

  # Pecl Intl
  # NOTE: It'd be nice to run this first, right after we interacted with the
  #       user, but it needs PHP to be installed. So, whatever, interruption!
  echo
  echo "NOTE: The pecl intl installer will axe you a question."
  echo "Just hit return when asked where the ICU directory is."
  echo
  # Specify where ICU libraries and headers can be found [DEFAULT] : 
  # 2014.05.14: We ./configure --enable-intl when we build PHP, so this may
  #             no longer be necessary:
  # 2015.01.25: We could use `expect` to truly automate this install...
  sudo pecl install intl
  # Weird, the permissions are 0640.
  # 2014.12.02: This path doesn't exist after previous command on Mint 17.1.
  if [[ -e /usr/local/lib/php/extensions/no-debug-zts-20100525/intl.so ]]; then
    sudo /bin/chmod 755 \
      /usr/local/lib/php/extensions/no-debug-zts-20100525/intl.so
  else
    echo
    echo "WARNING: Could not find intl.so; please find it and fix me."
    echo
  fi

} # end: stage_4_intl_install

stage_4_php5_install () {

  # Download PHP source.

  # -O doesn't work with -N so just download as is and then rename.
  # And use a special directory because the download name is obscure.
  mkdir -p ${OPT_DLOADS}/php-${PHP_5X}.download
  cd ${OPT_DLOADS}/php-${PHP_5X}.download
  #wget -N http://us1.php.net/get/php-${PHP_5X}.tar.gz/from/this/mirror
  wget -N http://php.net/get/php-${PHP_5X}.tar.gz/from/this/mirror
  cd ${OPT_DLOADS}/
  /bin/rm -f ${OPT_DLOADS}/php-${PHP_5X}.tar.gz
  /bin/ln -s php-${PHP_5X}.download/mirror php-${PHP_5X}.tar.gz
  /bin/rm -rf ${OPT_DLOADS}/php-${PHP_5X}/
  tar -zxvf php-${PHP_5X}.tar.gz

  # The new x64s have assumed /usr/lib as their own, rather
  # than /usr/lib64, so old software might be looking for
  # 32-bit libraries in the old standard location, /usr/lib,
  # but now they're found in /usr/lib/x86_64-linux-gnu.
  # So this is very much a hack that could easily break
  # if an app expected 64-bit ldap libs... but it seems to work.
  sudo /bin/ln -s \
    /usr/lib/x86_64-linux-gnu/libldap.so \
    /usr/lib/libldap.so
  sudo /bin/ln -s \
    /usr/lib/x86_64-linux-gnu/libldap_r.so \
    /usr/lib/libldap_r.so
  sudo /bin/ln -s \
    /usr/lib/x86_64-linux-gnu/liblber.so \
    /usr/lib/liblber.so

  # -- Build PHP

  cd ${OPT_DLOADS}/php-${PHP_5X}
  if [[ -e ${OPT_DLOADS}/php-${PHP_5X}/Makefile ]]; then
    make clean
  fi
  ./configure \
    --enable-maintainer-zts \
    --with-mysql \
    --with-pgsql \
    --with-apxs2=/usr/bin/apxs2 \
    --with-zlib \
    --with-ldap \
    --with-gd \
    --with-jpeg-dir \
    --with-iconv-dir \
    --enable-mbstring \
    --enable-intl
  make
  # You might also want to run:
  #  make test
  # but it triggers a known bug and you are asked to send a bug
  # email (all versions I've tried through 5.6.2).
  # So it's not enabled for this "automated" install.

  # The docs say to stop Apache before installing.
  sudo /etc/init.d/apache2 stop
  sudo make install
  sudo /etc/init.d/apache2 start
  # [lb] is not convinced this is necessary. And it fails at the end:
  #        Do you want to send this report now? [Yns]:
  #      You'll want to answer 'n' since we haven't configured email.
  #  make test

  # For whatever reason, make install didn't install a config file.
  # (Well, it does to /etc/php5/apache2/, but it doesn't use that one.)
  # ((Hint: run `php -i | grep ini` to see where it looks.))
  sudo /bin/cp \
    ${OPT_DLOADS}/php-${PHP_5X}/php.ini-development \
    /usr/local/lib/php.ini
  # Make sure www-data can read the file.
  sudo chmod 644 /usr/local/lib/php.ini

  # Set the timezone.
  sudo /bin/sed -i.bak \
    "s/^;date.timezone =/date.timezone = $USE_TIMEZONE/" \
    /usr/local/lib/php.ini

  # Loves to restart.
  sudo /etc/init.d/apache2 restart

} # end: stage_4_php5_install

stage_4_apc_install () {

  # APC User Cache.
  #
  # -O doesn't work with -N so just download as is and then rename.
  # And use a subdir to keep strays out of .downloads.
  cd ${OPT_DLOADS}
  mkdir -p ${OPT_DLOADS}/apcu-${APCU_V4}.download
  cd ${OPT_DLOADS}/apcu-${APCU_V4}.download
  #wget -N https://github.com/krakjoe/apcu/archive/${APCU_TGZ}
  wget -N http://pecl.php.net/get/${APCU_TGZ}
  cd ${OPT_DLOADS}/
  /bin/rm -f ${OPT_DLOADS}/apcu-${APCU_V4}.tar.gz
  /bin/ln -s apcu-${APCU_V4}.download/${APCU_TGZ} \
             apcu-${APCU_V4}.tar.gz
  /bin/rm -rf ${OPT_DLOADS}/apcu-${APCU_V4}
  gunzip -c apcu-${APCU_V4}.tar.gz | tar xf -
  cd ${OPT_DLOADS}/apcu-${APCU_V4}
  # Unalias the cp command for phpize...
  # Ha. If we don't run as sudo, phpize fails:
  #   me@machine:apcu-${APCU_V4} $ /usr/local/bin/phpize
  #    Configuring for:
  #    PHP Api Version:         20100412
  #    Zend Module Api No:      20100525
  #    Zend Extension Api No:   220100525
  #    cp: cannot stat 'run-tests*.php': No such file or directory
  #  because /usr/local/lib/php/build is off limits.
  sudo /usr/local/bin/phpize
  # The phpize results in some files owned by root.
  sudo chown -R $USER:$USER ${OPT_DLOADS}/apcu-${APCU_V4}
  ./configure --with-php-config=/usr/local/bin/php-config
  make
  # MAYBE, Or do it yourself:
  #         make test
  #        but you'll get an error like with PHP compile that
  #        requires intervention so cannot automate `make test`.
  sudo make install

  # MAYBE: php.ini settings we might want to set.
  #
  #apc.enabled=1
  #apc.shm_size=32M
  #apc.ttl=7200
  #apc.enable_cli=1

  # 2014.03.13: MediaWiki stopped working. Firefox windows are loaded,
  # but refresh says "Fatal exception of type MWException", and enabling
  # $wgShowExceptionDetails in LocalSettings.php says "CACHE_ACCEL requested
  # but no suitable object cache is present. You may want to install APC."
  # Weird. I might have installed something with PIP and messed up
  # permissions, or maybe I uninstalled something and whacked APC...?
  #  Nope: sudo apt-get install -y php-apc
  #  I reinstalled APC from source...
  # See also:
  #  php -r 'phpinfo();' | grep apc
  #
  # ARGH: I think it was 'sudo apt-get upgrade':
  # $ php --version
  # PHP 5.4.24 (cli) (built: Jan 28 2014 15:16:11) 
  # $ php5 --version
  # PHP 5.5.3-1ubuntu2.2 (cli) (built: Feb 28 2014 20:06:05) 
  #
  # I reinstalled (newer versions of) MediaWiki and APC.
  # For MediaWiki, after you make the new folder in /ccp/var/cms:
  #   cd ${mwiki_basepath}
  #   sudo cp -a ../mediawiki-1.22.0/LocalSettings.php .
  #   sudo /bin/cp -a \
  #     ../mediawiki-1.22.0/skins/common/images/mediawiki_custom.png \
  #     skins/common/images/
  #   php maintenance/update.php
  # and then update /etc/apache2/sites-available/mediawiki.conf
  # and restart Apache.
  
} # end: stage_4_apc_install

stage_4_php5_configure () {

    # 2014.04.17: Don't include intl.so. It's now part of the newer PHP.
    # The newer PHP uses /usr/local/lib/php/extensions/no-debug-zts-20121212,
    #  and there's no intl.so there within.
    # EXPLAIN: What happened? Did we miss something in the build process,
    #          or is intl integrated into the base package now?

    echo "
; [For MediaWiki, Added by ${0} at `date +%Y.%m.%d-%T`]:
; APC User Cache and I18N.
extension=apcu.so
;extension=intl.so
; Do we need to rename these for PHP5.6?
;extension=php_apcu.so
;;extension=php_intl.so


error_log = /ccp/var/log/mediawiki/php_errors.log
" | sudo tee -a /usr/local/lib/php.ini &> /dev/null

} # end: stage_4_php5_configure

stage_4_mediawiki_install () {

  # *** MediaWiki Install

  # -- Download and configure MediaWiki.

  cd ${OPT_DLOADS}
  wget -N ${mwiki_wgetpath}
  # Make the final directory, e.g., /ccp/var/cms/${mwiki_basename}.
  if [[ -d ${mwiki_basepath} ]]; then
    echo
    echo "WARNING: MediaWiki installation already exists. Skipping."
    echo
  else
    # Unpack to ${OPT_DLOADS} and then move to /ccp/var/cms.
    /bin/rm -rf ${mwiki_basename}
    tar -zxvf ${mwiki_basename}.tar.gz
    /bin/mkdir -p /ccp/var/cms/
    /bin/mv ${mwiki_basename} ${mwiki_basepath}
  fi
  cd ${mwiki_basepath}
  # Old apache versions: chmod a+w config
  sudo chown -R www-data:${USE_PROJECT_GROUP_MAIN} ${mwiki_basepath}
  sudo chmod 2775 ${mwiki_basepath}
  sudo chmod 2777 ${mwiki_basepath}/mw-config

  # Create and configure the Wiki db user.

  psql --no-psqlrc -U postgres -c "
    CREATE USER wikiuser
    WITH NOCREATEDB NOCREATEROLE NOSUPERUSER ENCRYPTED
    PASSWORD '$USE_PSQLWIKIPWD'"
  psql --no-psqlrc -U postgres -c "
    CREATE DATABASE wikidb WITH OWNER=wikiuser ENCODING='UTF8';"
  psql --no-psqlrc -U postgres -c "
    GRANT SELECT ON pg_ts_config TO wikiuser;" wikidb
  psql --no-psqlrc -U postgres -c "
    GRANT SELECT ON pg_ts_config_map TO wikiuser;" wikidb
  psql --no-psqlrc -U postgres -c "
    GRANT SELECT ON pg_ts_dict TO wikiuser;" wikidb
  psql --no-psqlrc -U postgres -c "
    GRANT SELECT ON pg_ts_parser TO wikiuser;" wikidb

  # Configure the Web server for MediaWiki.

  # Make an apache config.
  m4 \
    --define=MWIKI_BASENAME=$mwiki_basename \
    --define=MACH_DOMAIN=$USE_DOMAIN \
      ${script_absbase}/common/etc/apache2/sites-available/mediawiki \
      > /etc/apache2/sites-available/mediawiki.conf

  # Activate the apache conf.
  if [[ ! -e /etc/apache2/sites-enabled/mediawiki.conf ]]; then
    cd /etc/apache2/sites-enabled/
    ln -s ../sites-available/mediawiki.conf mediawiki.conf
  fi

  #sudo /etc/init.d/apache2 reload
  sudo /etc/init.d/apache2 restart

  # Ideally, we'd generate a LocalSetting.php file via the command line, but
  # it doesn't seem to produce the same file as going through the Web
  # installer (e.g., at http://mediawiki). For one, if your $wgSitename is
  # non-conformist, e.g., "[lb]", the Web installer adds to LocalSettings,
  #  $wgMetaNamespace = "Lb";
  # but the CLI installer doesn't do this. (And for another, the Web
  # installer will set $wgLogo = "$wgStylePath/common..." but the CLI
  # installer sets $wgLogo ="/wiki/skins/common...". So the Web installer
  # definitely seems like the better one for which to generate the config.
  #
  # So if we're going to automate the MediaWiki installation, we might as
  # well pre-generate a LocalSettings.php using the Web installer and just
  # use m4 to configure it here... 'tevs, man.
  #
  # This is the CLI code. We could run this and then make appropriate changes
  # using, e.g., `sed`, but, as discussed above, let's just use m4 on a file
  # we've previously generated using the Web installer.
  if false; then
    # Mandatory arguments:
    #  <name>: The name of the wiki
    #  <admin>: The username of the wiki administrator (WikiSysop)
    # The rest of the arguments should make sense.
    #  --installdbuser: The user to use for installing (root)
    #  --installdbpass: The pasword for the DB user to install as.
    cd ${mwiki_basepath}
    sudo php maintenance/install.php \
      --scriptpath "" \
      \
      --dbtype "postgres" \
      \
      --dbuser "wikiuser" \
      --dbpass "$USE_PSQLWIKIPWD" \
      \
      --dbname "wikidb" \
      \
      --installdbuser "wikiuser" \
      --installdbpass "$USE_PSQLWIKIPWD" \
      \
      --pass "$USE_WIKIUSERPASS" \
      $USE_WIKINAME \
      $USE_WIKIUSERNAME 
  fi # end: Not using the MediaWiki CLI installer.

  # 2014.11.05: How to upgrade mediawiki. Install MediaWiki,
  # PHP, and APCU, etc., and check that the Web site works
  # and shows the Let's Get Started screen. Then, do this:
  if false; then
    old_mwiki_basename="mediawiki-1.22.5"
    new_mwiki_basename="mediawiki-1.23.6"
    cd /ccp/var/cms
    /bin/cp ${old_mwiki_basename}/LocalSettings.php ${new_mwiki_basename}/
    /bin/cp ${old_mwiki_basename}/skins/common/images/mediawiki_custom.png \
      ${new_mwiki_basename}/
    cd /ccp/var/cms/${new_mwiki_basename}
    php maintenance/update.php
    # You're done!
  fi

  # Install the logo for your mediawiki site.

  wiki_base=/ccp/var/cms/${mwiki_basename}
  wk_images=${wiki_base}/skins/common/images
  # NOTE: $wk_images is 0771, so you can't ls it.
  sudo /bin/cp \
    $USE_WIKISITELOGO \
    ${wk_images}/mediawiki_custom.png

  sudo /bin/chmod 0660 ${wk_images}/mediawiki_custom.png
  sudo /bin/chown www-data:${USE_PROJECT_GROUP_MAIN} \
       ${wk_images}/mediawiki_custom.png

  # Install the LocalSettings file, and set the custom logo. Note that we
  # shouldn't just overwrite the existing logo, because that file may get
  # overwritten if you upgrade MediaWiki.

  # We have to make the namespace name...
  # See: mediawiki-1.22.0/includes/installer/WebInstallerPage.php
  #  // This algorithm should match the JS one in WebInstallerOutput.php
  #  $name = preg_replace( '/[\[\]\{\}|#<>%+? ]/', '_', $name );
  #  $name = str_replace( '&', '&amp;', $name );
  #  $name = preg_replace( '/__+/', '_', $name );
  #  $name = ucfirst( trim( $name, '_' ) );
  # We just copy the MediaWiki source and run a snippet of PHP from the CLI.
  META_NAMESPACE=$(
    php -r "
      \$name = '$USE_WIKINAME';
      \$name = preg_replace( '/[\[\]\{\}|#<>%+? ]/', '_', \$name );
      \$name = str_replace( '&', '&amp;', \$name );
      \$name = preg_replace( '/__+/', '_', \$name );
      \$name = ucfirst( trim( \$name, '_' ) );
      print \$name;
      "
    )

  # Make an intermediate LocalSettings.php, otherwise calling php
  # from the command line fails (and we want to generate some keys
  # using PHP).
  m4 \
    --define=NEW_WIKINAME="$USE_WIKINAME" \
    --define=META_NAMESPACE="$META_NAMESPACE" \
    --define=CUSTOM_LOGO_PNG="mediawiki_custom.png" \
    --define=MACH_DOMAIN="$USE_DOMAIN" \
    --define=DB_PASSWORD="$USE_PSQLWIKIPWD" \
    --define=SECRET_KEY="" \
    --define=UPGRADE_KEY="" \
      ${script_absbase}/target/mediawiki/LocalSettings.php \
      | sudo tee ${mwiki_basepath}/LocalSettings.php &> /dev/null

  # See mediawiki-1.22.0/includes/installer/Installer.php::doGenerateKeys
  sudo /bin/cp \
    ${script_absbase}/target/mediawiki/regenerateSecretKey.php \
    ${mwiki_basepath}/maintenance
  sudo chown www-data:${USE_PROJECT_GROUP_MAIN} \
    ${mwiki_basepath}/maintenance/regenerateSecretKey.php
  #sudo chmod 660 \
  sudo chmod 664 \
    ${mwiki_basepath}/maintenance/regenerateSecretKey.php
  SECRET_KEY=$(
    sudo -u www-data \
     php /ccp/var/cms/${mwiki_basename}/maintenance/regenerateSecretKey.php \
     --hexlen 64)
  UPGRADE_KEY=$(
    sudo -u www-data \
     php /ccp/var/cms/${mwiki_basename}/maintenance/regenerateSecretKey.php \
     --hexlen 16)

  # Make the final LocalSettings.php.
  m4 \
    --define=NEW_WIKINAME="$USE_WIKINAME" \
    --define=META_NAMESPACE="$META_NAMESPACE" \
    --define=CUSTOM_LOGO_PNG="mediawiki_custom.png" \
    --define=MACH_DOMAIN="$USE_DOMAIN" \
    --define=DB_PASSWORD="$USE_PSQLWIKIPWD" \
    --define=SECRET_KEY="$SECRET_KEY" \
    --define=UPGRADE_KEY="$UPGRADE_KEY" \
    ${script_absbase}/target/mediawiki/LocalSettings.php \
      | sudo tee ${mwiki_basepath}/LocalSettings.php &> /dev/null

  sudo chmod 660 ${mwiki_basepath}/LocalSettings.php
  sudo chown www-data:${USE_PROJECT_GROUP_MAIN} \
    ${mwiki_basepath}/LocalSettings.php
  #if [[ -n ${USE_PROJECT_GROUP_MAIN} ]]; then
  #  sudo chown ${USER}:${USE_PROJECT_GROUP_MAIN} \
  #  /ccp/var/cms/${mwiki_basename}/LocalSettings.php
  #
  #chmod 664 /ccp/var/cms/${mwiki_basename}/LocalSettings.php

  # NOTE: It can be convenient to make the MediaWiki directory 
  #       world-readable, so you don't have to sudo just to get a directory
  #       listing...
  #  sudo find ${wiki_base} -type d -exec chmod 2775 {} +
  #  sudo find ${wiki_base} -type f -exec chmod u+rw,g+rw,o+r {} +

  # If you made a new LocalSettings.php, save that file
  # but drop-replace the database that was created.

  # Download the remote file if the path is relative, indicating as such
  # (from $REMOTE_RESOURCES_URI).
  if [[ -n $USE_WIKIDB_DUMP && $(dirname $USE_WIKIDB_DUMP) == "." ]]; then
    if [[ -z $REMOTE_RESOURCES_URI ]]; then
      echo
      echo "ERROR: Set REMOTE_RESOURCES_URI or abs path for USE_WIKIDB_DUMP"
      exit 1
    fi
    cd /ccp/var/cms
    wget -N \
      --user "$REMOTE_RESOURCES_USER" \
      --password "$REMOTE_RESOURCES_PASS"
      $REMOTE_RESOURCES_URI/$USE_WIKIDB_DUMP
    if [[ $? -ne 0 || ! -e /ccp/var/cms/$USE_WIKIDB_DUMP ]]; then
      echo
      echo "WARNING: No MediaWiki dump: $REMOTE_RESOURCES_URI/$USE_WIKIDB_DUMP"
      echo
    else
      $USE_WIKIDB_DUMP = /ccp/var/cms/$USE_WIKIDB_DUMP
    fi
  fi

  if [[ -e $USE_WIKIDB_DUMP ]]; then

    psql --no-psqlrc -U postgres -c "
      DROP DATABASE wikidb;"
    psql --no-psqlrc -U postgres -c "
      CREATE DATABASE wikidb WITH OWNER=wikiuser ENCODING='UTF8';"
    psql --no-psqlrc -U postgres -c "
      GRANT SELECT ON pg_ts_config TO wikiuser;" wikidb
    psql --no-psqlrc -U postgres -c "
      GRANT SELECT ON pg_ts_config_map TO wikiuser;" wikidb
    psql --no-psqlrc -U postgres -c "
      GRANT SELECT ON pg_ts_dict TO wikiuser;" wikidb
    psql --no-psqlrc -U postgres -c "
      GRANT SELECT ON pg_ts_parser TO wikiuser;" wikidb

    # Load the existing Wiki database.
    psql --no-psqlrc -U postgres wikidb -f $USE_WIKIDB_DUMP

    # Upgrade the Wiki database to the current MediaWiki version.
    cd /ccp/var/cms/${mwiki_basename}
    sudo php maintenance/update.php

  fi

  # We can probably cleanup but this script is green, so retaining the db we
  # just loaded, at least for now.
  if false; then
    if [[ -e $USE_WIKIDB_DUMP ]]; then
      /bin/rm -f $USE_WIKIDB_DUMP
    fi
  fi

  #sudo /etc/init.d/apache2 reload
  sudo /etc/init.d/apache2 restart

} # end: stage_4_mediawiki_install

# ==============================================================
# Application Main()

setup_mediawiki_go () {

  if $DO_INSTALL_MEDIAWIKI; then

    # Interactive installations come first.
    # FIXME: This might not be necessary anymore.
    #        I think later versions of php5 include this library...
    if false; then
      # The i18n library used by php.
      # Just answer DEFAULT, I don't really know why they even ask.
      stage_4_intl_install
    fi

    stage_4_php5_install
    stage_4_apc_install
    stage_4_php5_configure

    stage_4_mediawiki_install

  fi

} # end: setup_mediawiki_go

setup_mediawiki_go

