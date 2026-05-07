#!/bin/bash
# 
swayidle -w timeout 300 '/bin/bash -c '\''gtklock & sleep 0.5; wlopm --off \*'\''' resume 'wlopm --on \*'
