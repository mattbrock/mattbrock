# Postfix-based mail system

These are the accompanying config files and scripts for my blog article [building a Postfix-based mail system for incoming and outgoing email, capable of successfully sending one million emails per day](https://cetre.co.uk/blog/building-a-postfix-based-mail-system-for-incoming-and-outgoing-email-capable-of-successfully-sending-one-million-emails-per-day/). There are five folders containing files which I've given installation locations for below. For explanations of what these are and how they're used, please refer to the blog post.

## [postfix](postfix)

* _aliases_ - local aliases file, installed at _/etc/aliases_.
* all other files - Postfix configuration files, installed in _/etc/postfix/_.

## [pypolicyd-spf](pypolicyd-spf)

* _policyd-spf.conf_ - config file for pypolicyd-spf, installed at _/etc/python-policyd-spf/policyd-spf.conf_.

## [opendkim](opendkim)

* _opendkim_ - startup parameters for OpenDKIM, installed at _/etc/sysconfig/opendkim_.
* _opendkim.conf_ - main config file, installed at _/etc/opendkim.conf_.
* _KeyTable_, _SigningTable_ and _TrustedHosts_ - key definitions and related config, installed in _/etc/opendkim/_.

## [postgrey](postgrey)

* _postgrey_ - startup parameters for Postgrey, installed at _/etc/sysconfig/postgrey_.
* _postgrey_whitelist_clients.local_ - config for manually whitelisting, installed at _/etc/postfix/postgrey_whitelist_clients.local_.

## [scripts](scripts)

* _autoreply.pl_, _block_sasl_fail.sh_, _bouncedmail.py_, _mailqueues.sh_ - various scripts, installed in _/usr/local/bin/_.
* _block_sasl_fail_, _mailqueues_ - cron files for above scripts, installed in _/etc/cron.d_.
* _pflogsumm_ - cron file for pflogsumm, installed in _/etc/cron.daily_. 
