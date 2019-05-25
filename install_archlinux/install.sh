#!/bin/bash
scp base_install.sh system_install.sh root@$1:
ssh -t root@$1 "./system_install.sh $2"
