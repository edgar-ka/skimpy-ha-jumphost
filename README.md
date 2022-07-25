# Jumphost in AWS with poormans HA
This code deploys an instance and configures some high availability for it. Main goal is to reduce bills.
This setup can ride on as little as t4g.nano and does not include any LB. It does HA by manipulating records in DNS hosted zone, which is a must in this case.

## Prerequisites

* Subscription to Debian AMIs provider (free)
* Hosted DNS zone (not so free)

# Status: WORK IN PROGRESS