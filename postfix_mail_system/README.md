# Postfix-based mail system

These are the accompanying config files and scripts for my blog post ["Building a Postfix-based mail system for incoming and outgoing email, capable of successfully sending one million emails per day"](foo.bar). There are five folders which I'll explain the contents of below.

## [opendkim](opendkim)

* [opendkim](opendkim/opendkim) - startup parameters for OpenDKIM, installed at _/etc/sysconfig/opendkim_.
* [opendkim.conf] - main config file, installed at _/etc/opendkim.conf_.
* KeyTable, SigningTable & TrustedHosts - key definitions and related config, installed in _/etc/opendkim/_.

## [postfix](postfix)

* aliases - local aliases file, installed at _/etc/aliases_.
* all other files - Postfix configuration files, installed in _/etc/postfix/_.

## [postgrey](postgrey)

* postgrey - startup parameters for Postgrey, installed at _/etc/sysconfig/postgrey_.
* postgrey_whitelist_clients.local - config for manually whitelisting, installed at _/etc/postfix/postgrey_whitelist_clients.local_.

## [pypolicyd-spf](pypolicyd-spf)

* policyd-spf.conf - config file for pypolicyd-spf, installed at _/etc/python-policyd-spf/policyd-spf.conf_.

## [scripts](scripts)

* autoreply.pl, block_sasl_fail.sh, bouncedmail.py, mailqueues.sh - various scripts, installed in _/usr/local/bin/_.
* block_sasl_fail, mailqueues - cron files for above scripts, installed in _/etc/cron.d_.
* pflogsumm - cron file for pflogsumm, installed in _/etc/cron.daily_.
